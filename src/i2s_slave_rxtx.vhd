library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity i2s_slave_rxtx is
    generic (
        G_INPUT_CLK_HZ  : integer := 50_000_000;
        G_DATA_WIDTH_RX : integer := 8;
        G_DATA_WIDTH_TX : integer := 8
    );
    port (
        clk_i     : in    std_logic;
        reset_n_i : in    std_logic;

        i2s_bclk_i   : in    std_logic;
        i2s_lrc_rx_i : in    std_logic;
        i2s_dat_rx_i : in    std_logic;
        i2s_lrc_tx_i : in    std_logic;
        i2s_dat_tx_o : out   std_logic;

        dat_rx_o       : out   std_logic_vector(G_DATA_WIDTH_RX - 1 downto 0);
        dat_rx_lr_o    : out   std_logic;
        dat_rx_valid_o : out   std_logic;

        dat_tx_i       : in    std_logic_vector(G_DATA_WIDTH_TX - 1 downto 0);
        dat_tx_lr_i    : in    std_logic;
        dat_tx_valid_i : in    std_logic;
        dat_tx_busy_o  : out   std_logic
    );
end entity i2s_slave_rxtx;

architecture rtl of i2s_slave_rxtx is

    component i2s_slave_rx is
        generic (
            G_DATA_WIDTH : integer
        );
        port (
            clk_i        : in    std_logic;
            reset_n_i    : in    std_logic;
            bclk_i       : in    std_logic;
            lrc_i        : in    std_logic;
            dat_i        : in    std_logic;
            dat_rx_o     : out   std_logic_vector(G_DATA_WIDTH - 1 downto 0);
            dat_rx_lr_o  : out   std_logic;
            dat_rx_valid : out   std_logic
        );
    end component i2s_slave_rx;

    component i2s_slave_tx is
        generic (
            G_DATA_WIDTH : integer
        );
        port (
            clk_i          : in    std_logic;
            reset_n_i      : in    std_logic;
            bclk_i         : in    std_logic;
            lrc_i          : in    std_logic;
            dat_o          : out   std_logic;
            dat_tx_i       : in    std_logic_vector(G_DATA_WIDTH - 1 downto 0);
            dat_tx_lr_i    : in    std_logic;
            dat_tx_valid_i : in    std_logic;
            dat_tx_busy_o  : out   std_logic
        );
    end component i2s_slave_tx;

begin

    i2s_slave_rx_inst : component i2s_slave_rx
        generic map (
            G_DATA_WIDTH => G_DATA_WIDTH_RX
        )
        port map (
            clk_i        => clk_i,
            reset_n_i    => reset_n_i,
            bclk_i       => i2s_bclk_i,
            lrc_i        => i2s_lrc_rx_i,
            dat_i        => i2s_dat_rx_i,
            dat_rx_o     => dat_rx_o,
            dat_rx_lr_o  => dat_rx_lr_o,
            dat_rx_valid => dat_rx_valid_o
        );

    i2s_slave_tx_inst : component i2s_slave_tx
        generic map (
            G_DATA_WIDTH => G_DATA_WIDTH_TX
        )
        port map (
            clk_i          => clk_i,
            reset_n_i      => reset_n_i,
            bclk_i         => i2s_bclk_i,
            lrc_i          => i2s_lrc_tx_i,
            dat_o          => i2s_dat_tx_o,
            dat_tx_i       => dat_tx_i,
            dat_tx_lr_i    => dat_tx_lr_i,
            dat_tx_valid_i => dat_tx_valid_i,
            dat_tx_busy_o  => dat_tx_busy_o
        );

end architecture rtl;
