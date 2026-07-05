library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity i2s_slave_rx is
    generic (
        G_DATA_WIDTH : integer := 8
    );
    port (
        mclk_i    : in    std_logic;
        reset_n_i : in    std_logic;

        bclk_i : in    std_logic;
        lrc_i  : in    std_logic;
        dat_i  : in    std_logic;

        dat_rx_o     : out   std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        dat_lr_o     : out   std_logic;
        dat_rx_ready : out   std_logic
    );
end entity i2s_slave_rx;

architecture rtl of i2s_slave_rx is

    signal bclk_prev  : std_logic := '0';
    signal lrc_prev   : std_logic := '0';
    signal dat_rx_out : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
begin

    main_p : process (mclk_i) is
        variable data_pointer : integer range -1 to G_DATA_WIDTH - 1 := G_DATA_WIDTH - 1;
        variable is_startup   : boolean                              := TRUE;
    begin
        if (rising_edge(mclk_i)) then
            if (reset_n_i = '0') then
                is_startup   := TRUE;
                data_pointer := G_DATA_WIDTH - 1;
                dat_rx_o     <= (others => '0');
                dat_rx_out   <= (others => '0');
                dat_rx_ready <= '0';
                bclk_prev    <= '0';
            else
                bclk_prev    <= bclk_i;
                lrc_prev     <= lrc_i;
                dat_rx_ready <= '0';

                if (bclk_i = '1' and bclk_prev = '0') then -- posedge bclk_i
                    if (lrc_i /= lrc_prev and not is_startup) then
                        dat_rx_o     <= dat_rx_out;
                        dat_rx_out   <= (others => '0');
                        dat_lr_o     <= lrc_prev;
                        dat_rx_ready <= '1';
                        data_pointer := G_DATA_WIDTH - 1;
                    end if;

                    is_startup               := FALSE;
                    dat_rx_out(data_pointer) <= dat_i;

                    if (data_pointer = 0) then
                        dat_rx_o     <= dat_rx_out;
                        dat_rx_out   <= (others => '0');
                        dat_lr_o     <= lrc_i;
                        dat_rx_ready <= '1';
                        data_pointer := G_DATA_WIDTH - 1;
                    else
                        data_pointer := data_pointer - 1;
                    end if;
                end if;
            end if;
        end if;
    end process main_p;
end architecture rtl;
