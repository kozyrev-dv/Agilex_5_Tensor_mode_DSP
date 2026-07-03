--------------------------------------------------------------------------------
--
--   FileName:         i2c_master.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 13.1 Build 162 SJ Full Version
--
--   HDL CODE is PROVIDED "AS is."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED to, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM to YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED to ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 11/01/2012 Scott Larson
--     Initial Public Release
--   Version 2.0 06/20/2014 Scott Larson
--     Added ability to interface with different slaves in the same transaction
--     Corrected ack_error bug where ack_error went 'Z' instead of '1' on error
--     Corrected timing of when ack_error signal clears
--   Version 2.1 10/21/2014 Scott Larson
--     Replaced gated clock with clock enable
--     Adjusted timing of SCL during start and stop conditions
--   Version 2.2 02/05/2015 Scott Larson
--     Corrected small SDA glitch introduced in version 2.1
--
--------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_1164.all;

entity i2c_master is
    generic (
        G_INPUT_CLK_HZ : integer := 50_000_000; -- input clock speed from user logic in Hz
        G_BUS_CLK_HZ   : integer := 400_000     -- speed the i2c bus (scl) will run at in Hz
    );
    port (
        clk_i       : in    std_logic;                    -- system clock
        reset_n_i   : in    std_logic;                    -- active low reset
        ena_i       : in    std_logic;                    -- latch in command
        addr_i      : in    std_logic_vector(6 downto 0); -- address of target slave
        rw_i        : in    std_logic;                    -- '0' is write, '1' is read
        data_wr_i   : in    std_logic_vector(7 downto 0); -- data to write to slave
        busy_o      : out   std_logic;                    -- indicates transaction in progress
        data_rd_o   : out   std_logic_vector(7 downto 0); -- data read from slave
        ack_error_o : buffer std_logic;                   -- flag if improper acknowledge from slave
        sda_io      : inout std_logic;                    -- serial data output of i2c bus
        scl_io      : inout std_logic                     -- serial clock output of i2c bus
    );
end entity i2c_master;

architecture logic of i2c_master is

    constant DIVIDER : integer := (G_INPUT_CLK_HZ / G_BUS_CLK_HZ) / 4; -- number of clocks in 1/4 cycle of scl

    type   fsm_state is (
        fsm_ready, fsm_start, fsm_addr, fsm_slv_ack1,
        fsm_write, fsm_read, fsm_slv_ack2, fsm_mstr_ack, fsm_stop
    );
    signal state         : fsm_state;                    -- state machine
    signal data_clk      : std_logic;                    -- data clock for sda
    signal data_clk_prev : std_logic;                    -- data clock during previous system clock
    signal scl_clk       : std_logic;                    -- constantly running internal scl
    signal scl_ena       : std_logic            := '0';  -- enables internal scl to output
    signal sda_int       : std_logic            := '1';  -- internal sda
    signal sda_ena_n     : std_logic;                    -- enables internal sda to output
    signal addr_rw       : std_logic_vector(7 downto 0); -- latched in address and read/write
    signal data_tx       : std_logic_vector(7 downto 0); -- latched in data to write to slave
    signal data_rx       : std_logic_vector(7 downto 0); -- data received from slave
    signal bit_cnt       : integer range 0 to 7 := 7;    -- tracks bit number in transaction
    signal stretch       : std_logic            := '0';  -- identifies if slave is stretching scl
begin

    -- generate the timing for the bus clock (scl_clk) and the data clock (data_clk)
    i2c_clk_gen : process (clk_i) is
        variable count : integer range 0 to DIVIDER * 4;  -- timing for clock generation
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then                           -- reset asserted
                stretch       <= '0';
                count         := 0;
                data_clk      <= '0';
                data_clk_prev <= '0';
                scl_clk       <= '0';
            else
                data_clk_prev <= data_clk;                      -- store previous value of data clock
                if (count = DIVIDER * 4 - 1) then               -- end of timing cycle
                    count := 0;                                 -- reset timer
                elsif (stretch = '0') then                      -- clock stretching from slave not detected
                    count := count + 1;                         -- continue clock generation timing
                end if;

                case count is                                   --  generates data_clk 90 deg. off the scl_clk

                    when 0 to DIVIDER - 1 =>                    -- first 1/4 cycle of clocking
                        scl_clk  <= '0';
                        data_clk <= '0';

                    when DIVIDER to (DIVIDER * 2 - 1) =>        -- second 1/4 cycle of clocking
                        scl_clk  <= '0';
                        data_clk <= '1';

                    when DIVIDER * 2 to (DIVIDER * 3 - 1) =>    -- third 1/4 cycle of clocking
                        scl_clk <= '1';                         -- release scl
                        if (scl_io = '0') then                  -- detect if slave is stretching clock
                            stretch <= '1';
                        else
                            stretch <= '0';
                        end if;
                        data_clk <= '1';

                    when others =>                              -- last 1/4 cycle of clocking
                        scl_clk  <= '1';
                        data_clk <= '0';
                end case;
            end if;
        end if;
    end process i2c_clk_gen;
    -- state machine and writing to sda during scl low (data_clk rising edge)
    fsm : process (clk_i) is
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then                                            -- reset asserted
                state       <= fsm_ready;                                        -- return to initial state
                busy_o      <= '1';                                              -- indicate not available
                scl_ena     <= '0';                                              -- sets scl high impedance
                sda_int     <= '1';                                              -- sets sda high impedance
                ack_error_o <= '0';                                              -- clear acknowledge error flag
                bit_cnt     <= 7;                                                -- restarts data bit counter
                data_rd_o   <= "00000000";                                       -- clear data read port
                addr_rw     <= (others => '0');
                data_rx     <= (others => '0');
                data_tx     <= (others => '0');

            --  all sda drive control for write and preparation for read
            elsif (data_clk = '1' and data_clk_prev = '0') then                  -- data clock rising edge

                case state is

                    when fsm_ready =>                                            -- idle state
                        if (ena_i = '1') then                                    -- transaction requested
                            busy_o  <= '1';                                      -- flag busy
                            addr_rw <= addr_i & rw_i;                            -- collect requested slave address and command
                            data_tx <= data_wr_i;                                -- collect requested data to write
                            state   <= fsm_start;                                -- go to start bit
                        else                                                     -- remain idle
                            busy_o <= '0';                                       -- unflag busy
                            state  <= fsm_ready;                                 -- remain idle
                        end if;

                    when fsm_start =>                                            -- start bit of transaction
                        busy_o  <= '1';                                          -- resume busy if continuous mode
                        sda_int <= addr_rw(bit_cnt);                             -- set first address bit to bus
                        state   <= fsm_addr;                                     -- go to command

                    when fsm_addr =>                                             -- address and command byte of transaction
                        if (bit_cnt = 0) then                                    -- command transmit finished
                            busy_o  <= '0';                                      -- resume busy if continuous mode
                            sda_int <= '1';                                      -- release sda for slave acknowledge
                            bit_cnt <= 7;                                        -- reset bit counter for "byte" states
                            state   <= fsm_slv_ack1;                             -- go to slave acknowledge (command)
                        else                                                     -- next clock cycle of command state
                            busy_o  <= '1';                                      -- resume busy if continuous mode
                            bit_cnt <= bit_cnt - 1;                              -- keep track of transaction bits
                            sda_int <= addr_rw(bit_cnt - 1);                     -- write address/command bit to bus
                            state   <= fsm_addr;                                 -- continue with command
                        end if;

                    when fsm_slv_ack1 =>                                         -- slave acknowledge bit (command)
                        busy_o <= '1';                                           -- resume busy if continuous mode
                        if (addr_rw(0) = '0') then                               -- write command
                            sda_int <= data_tx(bit_cnt);                         -- write first bit of data
                            state   <= fsm_write;                                -- go to write byte
                        else                                                     -- read command
                            sda_int <= '1';                                      -- release sda from incoming data
                            state   <= fsm_read;                                 -- go to read byte
                        end if;

                    when fsm_write =>                                            -- write byte of transaction
                        if (bit_cnt = 0) then                                    -- write byte transmit finished
                            sda_int <= '1';                                      -- release sda for slave acknowledge
                            bit_cnt <= 7;                                        -- reset bit counter for "byte" states
                            busy_o  <= '0';                                      -- continue is accepted
                            state   <= fsm_slv_ack2;                             -- go to slave acknowledge (write)
                        else                                                     -- next clock cycle of write state
                            busy_o  <= '1';                                      -- resume busy if continuous mode
                            bit_cnt <= bit_cnt - 1;                              -- keep track of transaction bits
                            sda_int <= data_tx(bit_cnt - 1);                     -- write next bit to bus
                            state   <= fsm_write;                                -- continue writing
                        end if;

                    when fsm_read =>                                             -- read byte of transaction
                        busy_o <= '1';                                           -- resume busy if continuous mode
                        if (bit_cnt = 0) then                                    -- read byte receive finished
                            if (ena_i = '1' and addr_rw = addr_i & rw_i) then    -- continuing with another read at same address
                                sda_int <= '0';                                  -- acknowledge the byte has been received
                            else                                                 -- stopping or continuing with a write
                                sda_int <= '1';                                  -- send a no-acknowledge (before stop or repeated start)
                            end if;
                            bit_cnt   <= 7;                                      -- reset bit counter for "byte" states
                            data_rd_o <= data_rx;                                -- output received data
                            state     <= fsm_mstr_ack;                           -- go to master acknowledge
                        else                                                     -- next clock cycle of read state
                            bit_cnt <= bit_cnt - 1;                              -- keep track of transaction bits
                            state   <= fsm_read;                                 -- continue reading
                        end if;

                    when fsm_slv_ack2 =>                                         -- slave acknowledge bit (write)
                        if (ena_i = '1') then                                    -- continue transaction
                            addr_rw <= addr_i & rw_i;                            -- collect requested slave address and command
                            data_tx <= data_wr_i;                                -- collect requested data to write
                            if (addr_rw = addr_i & rw_i) then                    -- continue transaction with another write
                                busy_o  <= '1';
                                sda_int <= data_wr_i(bit_cnt);                   -- write first bit of data
                                state   <= fsm_write;                            -- go to write byte
                            else                                                 -- continue transaction with a read or new slave
                                busy_o <= '1';
                                state  <= fsm_start;                             -- go to repeated start
                            end if;
                        else                                                     -- complete transaction
                            state  <= fsm_stop;                                  -- go to stop bit
                            busy_o <= '0';                                       -- continue is accepted
                        end if;

                    when fsm_mstr_ack =>                                         -- master acknowledge bit after a read
                        if (ena_i = '1') then                                    -- continue transaction
                            busy_o  <= '0';                                      -- continue is accepted and data received is available on bus
                            addr_rw <= addr_i & rw_i;                            -- collect requested slave address and command
                            data_tx <= data_wr_i;                                -- collect requested data to write
                            if (addr_rw = addr_i & rw_i) then                    -- continue transaction with another read
                                sda_int <= '1';                                  -- release sda from incoming data
                                state   <= fsm_read;                             -- go to read byte
                            else                                                 -- continue transaction with a write or new slave
                                state <= fsm_start;                              -- repeated start
                            end if;
                        else                                                     -- complete transaction
                            state <= fsm_stop;                                   -- go to stop bit
                        end if;

                    when fsm_stop =>                                             -- stop bit of transaction
                        busy_o <= '0';                                           -- unflag busy
                        state  <= fsm_ready;                                     -- go to idle state
                end case;
            --  read states and checks for acks
            elsif (data_clk = '0' and data_clk_prev = '1') then                  -- data clock falling edge

                case state is

                    when fsm_start =>
                        if (scl_ena = '0') then                                  -- starting new transaction
                            scl_ena     <= '1';                                  -- enable scl output
                            ack_error_o <= '0';                                  -- reset acknowledge error output
                        end if;

                    when fsm_slv_ack1 =>                                         -- receiving slave acknowledge (command)
                        if (sda_io /= '0' or ack_error_o = '1') then             -- no-acknowledge or previous no-acknowledge
                            ack_error_o <= '1';                                  -- set error output if no-acknowledge
                        end if;

                    when fsm_read =>                                             -- receiving slave data
                        data_rx(bit_cnt) <= sda_io;                              -- receive current slave data bit

                    when fsm_slv_ack2 =>                                         -- receiving slave acknowledge (write)
                        if (sda_io /= '0' or ack_error_o = '1') then             -- no-acknowledge or previous no-acknowledge
                            ack_error_o <= '1';                                  -- set error output if no-acknowledge
                        end if;

                    when fsm_stop =>
                        scl_ena <= '0';                                          -- disable scl

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process fsm;
    -- set sda output
    with state select sda_ena_n <=
        data_clk_prev when fsm_start,    -- generate start condition
        not data_clk_prev when fsm_stop, -- generate stop condition
        sda_int when others;             -- set to internal sda signal

    -- set scl and sda outputs
    scl_io <= '0' when (scl_ena = '1' and scl_clk = '0') else
              'Z';
    sda_io <= '0' when sda_ena_n = '0' else
              'Z';
end architecture logic;
