library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;

entity audio_process_top is
    generic (
        G_INPUT_CLK_HZ : integer := 50_000_000;
        -- SSM2603 configutation
        G_AUD_CLK_HZ          : integer := 12_228_000;
        G_AUD_CONFIG_DELAY_US : integer := 10;
        G_AUD_I2S_DATA_WIDTH  : integer := 24;
        -- DSP processing
        G_DSP_DATA_WIDTH : integer := 8
    );
    port (
        clk     : in    std_logic;
        clk_aud : in    std_logic; -- 12.288 MHz from external PLL
        reset_n : in    std_logic;

        -- I2C Interface (Connected to FPGA_I2C_SCL/SDA)
        fpga_i2c_scl : inout std_logic;
        fpga_i2c_sda : inout std_logic;

        -- Audio CODEC Interface (FPGA is Master)
        aud_xck     : out   std_logic; -- 12.288 MHz chip clock to SSM2603 MCLK pin
        aud_bclk    : in    std_logic;
        aud_adclrck : out   std_logic;
        aud_adcdat  : in    std_logic; -- recording data
        aud_daclrck : out   std_logic;
        aud_dacdat  : out   std_logic  -- playback data
    );
end entity audio_process_top;

architecture rtl of audio_process_top is

    component ssm2603_config is
        generic (
            G_INPUT_CLK_HZ  : integer := 50_000_000;
            G_DEVICE_ADDR   : integer := 16#36#;
            G_DELAY_TIME_US : integer := 1000
        );
        port (
            clk_i           : in    std_logic;
            reset_n_i       : in    std_logic;
            ena_i           : in    std_logic;
            busy_o          : out   std_logic;
            i2c_ena_o       : out   std_logic;
            i2c_addr_o      : out   std_logic_vector(6 downto 0);
            i2c_rw_o        : out   std_logic;
            i2c_data_wr_o   : out   std_logic_vector(7 downto 0);
            i2c_busy_i      : in    std_logic;
            i2c_ack_error_i : in    std_logic
        );
    end component ssm2603_config;

    component i2c_master is
        generic (
            G_INPUT_CLK_HZ : integer := 50_000_000;
            G_BUS_CLK_HZ   : integer := 400_000
        );
        port (
            clk_i       : in    std_logic;
            reset_n_i   : in    std_logic;
            ena_i       : in    std_logic;
            addr_i      : in    std_logic_vector(6 downto 0);
            rw_i        : in    std_logic;
            data_wr_i   : in    std_logic_vector(7 downto 0);
            busy_o      : out   std_logic;
            data_rd_o   : out   std_logic_vector(7 downto 0);
            ack_error_o : buffer std_logic;
            sda_io      : inout std_logic;
            scl_io      : inout std_logic
        );
    end component i2c_master;

    component i2s_slave_rxtx is
        generic (
            G_INPUT_CLK_HZ  : integer := 50_000_000;
            G_DATA_WIDTH_RX : integer;
            G_DATA_WIDTH_TX : integer
        );
        port (
            clk_i          : in    std_logic;
            reset_n_i      : in    std_logic;
            i2s_bclk_i     : in    std_logic;
            i2s_lrc_rx_i   : in    std_logic;
            i2s_dat_rx_i   : in    std_logic;
            i2s_lrc_tx_o   : in    std_logic;
            i2s_dat_tx_o   : out   std_logic;
            dat_rx_o       : out   std_logic_vector(G_DATA_WIDTH_RX - 1 downto 0);
            dat_rx_lr_o    : out   std_logic;
            dat_rx_valid_o : out   std_logic;
            dat_tx_i       : in    std_logic_vector(G_DATA_WIDTH_TX - 1 downto 0);
            dat_tx_lr_i    : in    std_logic;
            dat_tx_valid_i : in    std_logic
        );
    end component i2s_slave_rxtx;

    signal reset_hard_n : std_logic;

    -- Audio CODEC signals
    signal ena_aud_config         : std_logic;
    signal busy_aud_config        : std_logic;
    signal aud_config_i2c_ena     : std_logic                    := '0';
    signal aud_config_i2c_addr    : std_logic_vector(6 downto 0) := "0011011"; -- 0x1B (0x36 write address)
    signal aud_config_i2c_rw      : std_logic                    := '0';
    signal aud_config_i2c_data_wr : std_logic_vector(7 downto 0) := (others => '0');

    -- I2C Master Control Signals
    signal i2c_ena       : std_logic                    := '0';
    signal i2c_addr      : std_logic_vector(6 downto 0) := "0011011"; -- 0x1B (0x36 write address)
    signal i2c_rw        : std_logic                    := '0';
    signal i2c_data_wr   : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_data_rd   : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_busy      : std_logic;
    signal i2c_ack_error : std_logic;

    signal i2c_data_rd_out   : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_busy_out      : std_logic;
    signal i2c_ack_error_out : std_logic;

    -- codec config FSM States

    type   state_type is (init, aud_codec_config, active);
    signal state : state_type := init;

    -- DSP buffering signals
    signal dat_rx_out       : std_logic_vector(G_AUD_I2S_DATA_WIDTH - 1 downto 0);
    signal dat_rx_lr_out    : std_logic;
    signal dat_rx_valid_out : std_logic;
    signal dat_tx_in        : std_logic_vector(G_AUD_I2S_DATA_WIDTH - 1 downto 0);
    signal dat_tx_lr_in     : std_logic;
    signal dat_tx_valid_in  : std_logic;
begin

    -------------------------------------------------------------------
    -- 1. CLOCK GENERATION
    -------------------------------------------------------------------
    aud_xck <= clk_aud;

    -------------------------------------------------------------------
    -- 2. DIGITAL AUDIO LOOPBACK
    -------------------------------------------------------------------

    i2s_slave_rxtx_inst : component i2s_slave_rxtx
        generic map (
            G_INPUT_CLK_HZ  => G_INPUT_CLK_HZ,
            G_DATA_WIDTH_RX => 24,
            G_DATA_WIDTH_TX => 24
        )
        port map (
            clk_i          => clk,
            reset_n_i      => reset_hard_n,
            i2s_bclk_i     => aud_bclk,
            i2s_lrc_rx_i   => aud_adclrck,
            i2s_dat_rx_i   => aud_adcdat,
            i2s_lrc_tx_o   => aud_daclrck,
            i2s_dat_tx_o   => aud_dacdat,
            dat_rx_o       => dat_rx_out,
            dat_rx_lr_o    => dat_rx_lr_out,
            dat_rx_valid_o => dat_rx_valid_out,
            dat_tx_i       => dat_tx_in,
            dat_tx_lr_i    => dat_tx_lr_in,
            dat_tx_valid_i => dat_tx_valid_in
        );

    -------------------------------------------------------------------
    -- 3. AUD CODEC CONFIGURATION CONTROLLER
    -------------------------------------------------------------------
    ssm2603_config_inst : component ssm2603_config
        generic map (
            G_INPUT_CLK_HZ  => G_INPUT_CLK_HZ,
            G_DEVICE_ADDR   => 16#36#,
            G_DELAY_TIME_US => G_AUD_CONFIG_DELAY_US
        )
        port map (
            clk_i     => clk,
            reset_n_i => reset_hard_n,
            ena_i     => ena_aud_config,
            busy_o    => busy_aud_config,

            i2c_ena_o       => aud_config_i2c_ena,
            i2c_addr_o      => aud_config_i2c_addr,
            i2c_rw_o        => aud_config_i2c_rw,
            i2c_data_wr_o   => aud_config_i2c_data_wr,
            i2c_busy_i      => i2c_busy,
            i2c_ack_error_i => i2c_ack_error
        );

    -------------------------------------------------------------------
    -- 4. I2C MASTER INSTANTIATION
    -------------------------------------------------------------------
    i2c_mux : process (all) is
    begin
        i2c_ena       <= '0';
        i2c_addr      <= (others => '0');
        i2c_rw        <= '0';
        i2c_data_wr   <= (others => '0');
        i2c_data_rd   <= (others => '0');
        i2c_busy      <= '0';
        i2c_ack_error <= '0';

        case state is
            when aud_codec_config =>
                i2c_ena       <= aud_config_i2c_ena;
                i2c_addr      <= aud_config_i2c_addr;
                i2c_rw        <= aud_config_i2c_rw;
                i2c_data_wr   <= aud_config_i2c_data_wr;
                i2c_data_rd   <= i2c_data_rd_out;
                i2c_busy      <= i2c_busy_out;
                i2c_ack_error <= i2c_ack_error_out;
            when others =>
        end case;
    end process i2c_mux;

    name : process (clk) is
    begin
        if rising_edge(clk) then
            if (reset_hard_n = '0') then
                ena_aud_config <= '0';
                state          <= init;
            else

                case state is
                    when init =>
                        state          <= aud_codec_config;
                        ena_aud_config <= '0';
                    when aud_codec_config =>
                        ena_aud_config <= '1';
                        if (ena_aud_config = '1' and busy_aud_config = '0') then
                            state <= active;
                        end if;
                    when active =>
                        ena_aud_config <= '0';
                        state          <= active;
                    when others =>
                        ena_aud_config <= '0';
                        state          <= init;
                end case;
            end if;
        end if;
    end process name;

    i2c_master_inst : component i2c_master
        generic map (
            G_INPUT_CLK_HZ => G_INPUT_CLK_HZ,
            G_BUS_CLK_HZ   => 400_000
        )
        port map (
            clk_i       => clk,
            reset_n_i   => reset_hard_n,
            ena_i       => i2c_ena,
            addr_i      => i2c_addr,
            rw_i        => i2c_rw,
            data_wr_i   => i2c_data_wr,
            busy_o      => i2c_busy_out,
            data_rd_o   => i2c_data_rd_out,
            ack_error_o => i2c_ack_error_out,
            sda_io      => fpga_i2c_sda,
            scl_io      => fpga_i2c_scl
        );

    reset_hard_n <= reset_n and not(i2c_ack_error);
end architecture rtl;
