library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.std_logic_unsigned.all;

entity audio_process_top is
    generic (
        G_INPUT_CLK : integer := 50_000_000;
        G_AUD_CLK   : integer := 12_228_000
    );
    port (
        clk     : in    std_logic;
        clk_aud : in    std_logic; -- 12.288 MHz from external PLL
        reset_n : in    std_logic;

        -- I2C Interface (Connected to FPGA_I2C_SCL/SDA)
        fpga_i2c_scl : inout std_logic;
        fpga_i2c_sda : inout std_logic;

        -- Audio CODEC Interface (FPGA is Master)
        aud_xck     : out   std_logic;
        aud_bclk    : out   std_logic;
        aud_adclrck : out   std_logic;
        aud_adcdat  : in    std_logic;
        aud_daclrck : out   std_logic;
        aud_dacdat  : out   std_logic
    );
end entity audio_process_top;

architecture rtl of audio_process_top is

    component ssm2603_config is
        generic (
            G_INPUT_CLK   : integer := 50_000_000;
            G_DEVICE_ADDR : integer := 16#36#
        );
        port (
            clk             : in    std_logic;
            rst_n           : in    std_logic;
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

    signal i2c_data_rd_o   : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_busy_o      : std_logic;
    signal i2c_ack_error_o : std_logic;

    -- codec config FSM States

    type   state_type is (init, aud_codec_config, active);
    signal state : state_type := init;
begin

    -------------------------------------------------------------------
    -- 1. CLOCK GENERATION
    -------------------------------------------------------------------
    aud_xck <= clk_aud;

    -------------------------------------------------------------------
    -- 2. DIGITAL AUDIO LOOPBACK
    -------------------------------------------------------------------
    aud_dacdat <= aud_adcdat; -- given every

    -------------------------------------------------------------------
    -- 3. AUD CODEC CONFIGURATION CONTROLLER
    -------------------------------------------------------------------
    ssm2603_config_inst : component ssm2603_config
        generic map (
            g_input_clk   => G_INPUT_CLK,
            g_device_addr => 16#36#
        )
        port map (
            clk    => clk,
            rst_n  => reset_hard_n,
            ena_i  => ena_aud_config,
            busy_o => busy_aud_config,

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
                i2c_data_rd   <= i2c_data_rd_o;
                i2c_busy      <= i2c_busy_o;
                i2c_ack_error <= i2c_ack_error_o;

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
            g_input_clk_hz => G_INPUT_CLK,
            g_bus_clk_hz   => G_AUD_CLK
        )
        port map (
            clk_i       => clk,
            reset_n_i   => reset_hard_n,
            ena_i       => i2c_ena,
            addr_i      => i2c_addr,
            rw_i        => i2c_rw,
            data_wr_i   => i2c_data_wr,
            busy_o      => i2c_busy_o,
            data_rd_o   => i2c_data_rd_o,
            ack_error_o => i2c_ack_error_o,
            sda_io      => fpga_i2c_sda,
            scl_io      => fpga_i2c_scl
        );

    reset_hard_n <= reset_n and not(i2c_ack_error);
end architecture rtl;
