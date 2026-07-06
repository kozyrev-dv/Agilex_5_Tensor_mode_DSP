library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.basics_p;

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
        dat_rx_lr_o  : out   std_logic;
        dat_rx_valid : out   std_logic
    );
end entity i2s_slave_rx;

architecture rtl of i2s_slave_rx is

    constant DATA_P_TOP_ADDR : integer := G_DATA_WIDTH - 1;

    signal bclk_prev : std_logic := '0';
    signal lrc_prev  : std_logic := '0';
    -- signal dat_rx_out    : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal data_pointer     : integer range 0 to DATA_P_TOP_ADDR := DATA_P_TOP_ADDR;
    signal start_channel    : std_logic                          := '0';
    signal channel_received : std_logic;
begin

    start_channel <= lrc_i xor lrc_prev;

    main_p : process (clk_i) is
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then
                data_pointer     <= DATA_P_TOP_ADDR;
                dat_rx_o         <= (others => '0');
                dat_rx_valid     <= '0';
                bclk_prev        <= '0';
                channel_received <= '0';
            else
                bclk_prev    <= bclk_i;
                lrc_prev     <= lrc_i;
                dat_rx_valid <= '0';

                if (start_channel) then
                    data_pointer     <= DATA_P_TOP_ADDR;
                    channel_received <= '0';                                        -- prepare receiving data
                elsif (bclk_prev = '0' and bclk_i = '1') then                       -- posedge bclk_i
                    if (data_pointer /= 0) then
                        dat_rx_o(data_pointer) <= dat_i;
                        data_pointer           <= data_pointer - 1;
                        channel_received       <= '0';
                    else
                        if (channel_received = '0') then                            -- if not outputed - do that
                            dat_rx_o(data_pointer) <= dat_i;
                            dat_rx_valid           <= '1';
                            dat_rx_lr_o            <= lrc_i;
                            channel_received       <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process main_p;
end architecture rtl;
