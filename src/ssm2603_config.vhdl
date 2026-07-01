library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;

entity ssm2603_config is
    generic (
        G_INPUT_CLK : integer := 50_000_000;
        G_DEVICE_ADDR : integer := 16#36#
    );
    port(
        clk : in std_logic;
        rst_n : in std_logic;
        ena_i : in std_logic;
        busy_o : out std_logic;

        i2c_ena_o       : out std_logic;
        i2c_addr_o      : out std_logic_vector (6 downto 0);
        i2c_rw_o        : out std_logic;
        i2c_data_wr_o   : out std_logic_vector(7 downto 0);
        i2c_busy_i      : in std_logic;
        i2c_ack_error_i : in std_logic
    );
end entity ssm2603_config;

architecture rtl of ssm2603_config is
    -- I2C Configuration ROM (16 bits: 7-bit addr + 9-bit data)
    
    type config_rom_type is array (0 to 7) of std_logic_vector(15 downto 0);
    constant CONFIG_ROM : config_rom_type := (
        x"1E00", -- R15: Reset
        x"0C30", -- R6:  Power up ADC/DAC/MIC, keep OUT off
        x"0815", -- R4:  Mic in, Boost on, Unmute, DAC select
        x"0A00", -- R5:  DAC unmute
        x"0E4A", -- R7:  Master Mode, 24-bit, I2S format (0x0A)
        x"1000", -- R8:  48kHz base sampling rate
        x"1201", -- R9:  Activate digital core
        x"0C20"  -- R6:  Power up OUT
    );

    -- codec config FSM States
    type state_type is (INIT, TX_ADDR, TX_REG, TX_DATA, TX_DONE, DELAY, COMPLETE);
    signal state      : state_type := INIT;
    signal rom_index  : integer range 0 to 7 := 0;
    signal delay_cnt  : integer range 0 to G_INPUT_CLK / 1000 := 0;
    signal i2c_busy_prev : std_logic;

begin
    
    -------------------------------------------------------------------
    -- 4. I2C WRAPPER STATE MACHINE (2-Byte Transmission)
    -------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                i2c_ena_o <= '0';
                state <= INIT;
                i2c_data_wr_o <= (others => '0');
                rom_index <= 0;
                delay_cnt <= 0;
            elsif (ena_i = '1' and i2c_ack_error_i = '0') then
                case state is
                    when INIT =>
                        i2c_ena_o <= '0';
                        state <= TX_ADDR;
                        
                    when TX_ADDR =>
                        i2c_ena_o <= '1';
                        i2c_data_wr_o <= CONFIG_ROM(rom_index)(15 downto 8);
                        if (i2c_busy_prev = '1' and i2c_busy_i = '0') then
                            state <= TX_REG;
                        end if;
                        
                    when TX_REG =>
                        if (i2c_busy_prev = '1' and i2c_busy_i = '0') then
                            i2c_data_wr_o <= CONFIG_ROM(rom_index)(7 downto 0);
                            state <= TX_DATA;
                        else
                            i2c_data_wr_o <= CONFIG_ROM(rom_index)(15 downto 8);
                            state <= TX_REG;
                        end if;

                    when TX_DATA =>
                        i2c_data_wr_o <= CONFIG_ROM(rom_index)(7 downto 0);
                        if (i2c_busy_prev = '1' and i2c_busy_i = '0') then
                            i2c_ena_o <= '0';
                            state <= TX_DONE;
                        end if;

                    when TX_DONE =>
                        if i2c_busy_i = '0' then
                            if rom_index < CONFIG_ROM'length - 1 then
                                rom_index <= rom_index + 1;
                                state <= DELAY;
                            else
                                state <= COMPLETE; -- Configuration complete
                            end if;
                        end if;

                    when DELAY =>
                        -- Brief pause between I2C configurations
                        if delay_cnt = G_INPUT_CLK / 1000 then 
                            delay_cnt <= 0;
                            state <= TX_ADDR;
                        else
                            delay_cnt <= delay_cnt + 1;
                        end if;
                        
                    when COMPLETE =>
                        state <= COMPLETE;
                        i2c_ena_o <= '0';

                    when others =>
                        state <= INIT;
                        i2c_ena_o <= '0';
                end case;
            end if;
        end if;
    end process;

    process (clk) begin
        if (rising_edge(clk)) then
            if rst_n = '0' then
                i2c_busy_prev <= '0';
            else
                i2c_busy_prev <= i2c_busy_i;
            end if;
        end if;
    end process;

    busy_o <= '1' when (ena_i = '1') and (state /= COMPLETE) else '0'; 
    i2c_addr_o <= std_logic_vector(to_unsigned(G_DEVICE_ADDR, i2c_addr_o'length));
    i2c_rw_o <= '0';
end architecture rtl;
