library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity i2s_slave_rx is
    generic (
        G_DATA_WIDTH : integer := 8
    );
    port (
        clk_i     : in    std_logic;
        reset_n_i : in    std_logic;

        bclk_i : in    std_logic;
        lrc_i  : in    std_logic;
        dat_i  : in    std_logic;

        dat_rx_o     : out   std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        dat_lr_o     : out   std_logic;
        dat_rx_valid : out   std_logic
    );
end entity i2s_slave_rx;

architecture rtl of i2s_slave_rx is

    signal bclk_prev  : std_logic := '0';
    signal lrc_prev   : std_logic := '0';
    signal dat_rx_out : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
begin

    main_p : process (clk_i) is
        variable data_pointer : integer range -1 to G_DATA_WIDTH - 1 := G_DATA_WIDTH - 1;
        variable is_startup   : boolean                              := TRUE;
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then
                is_startup   := TRUE;
                data_pointer := G_DATA_WIDTH - 1;
                dat_rx_o     <= (others => '0');
                dat_rx_out   <= (others => '0');
                dat_rx_valid <= '0';
                bclk_prev    <= '0';
            else
                bclk_prev    <= bclk_i;
                lrc_prev     <= lrc_i;
                dat_rx_valid <= '0';
                if (lrc_i /= lrc_prev and not is_startup) then           -- master switched channel - burst the data as is
                    dat_rx_o               <= dat_rx_out;
                    dat_rx_o(data_pointer) <= dat_i;                     -- TODO: is it dat_i which goes here?
                    dat_rx_out             <= (others => '0');
                    dat_lr_o               <= lrc_prev;
                    dat_rx_valid           <= '1';
                    data_pointer           := G_DATA_WIDTH - 1;
                elsif (bclk_i = '1' and bclk_prev = '0') then            -- posedge bclk_i
                    if (data_pointer = 0) then                           -- it was given enough time to fill the buffer
                        dat_rx_o               <= dat_rx_out;
                        dat_rx_o(data_pointer) <= dat_i;
                        dat_rx_out             <= (others => '0');
                        dat_lr_o               <= lrc_i;
                        dat_rx_valid           <= '1';
                        data_pointer           := G_DATA_WIDTH - 1;
                    else                                                 -- buffer is still loading
                        is_startup               := FALSE;
                        dat_rx_out(data_pointer) <= dat_i;
                        data_pointer             := data_pointer - 1;
                    end if;
                end if;
            end if;
        end if;
    end process main_p;
end architecture rtl;
