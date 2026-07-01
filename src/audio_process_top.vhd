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
        clk      : in    std_logic;
        clk_aud    : in    std_logic; -- 12.288 MHz from external PLL
        reset_n       : in    std_logic;

        -- I2C Interface (Connected to FPGA_I2C_SCL/SDA)
        FPGA_I2C_SCL  : inout std_logic;
        FPGA_I2C_SDA  : inout std_logic;

        -- Audio CODEC Interface (FPGA is Master)
        AUD_XCK       : out   std_logic;
        AUD_BCLK      : out   std_logic;
        AUD_ADCLRCK   : out   std_logic;
        AUD_ADCDAT    : in    std_logic;
        AUD_DACLRCK   : out   std_logic;
        AUD_DACDAT    : out   std_logic
    );
end audio_process_top;

architecture rtl of audio_process_top is

    

    component ssm2603_config
        generic(
            G_INPUT_CLK   : integer := 50_000_000;
            G_DEVICE_ADDR : integer := 16#36#
        );
        port(
            clk             : in  std_logic;
            rst_n           : in  std_logic;
            ena_i           : in  std_logic;
            busy_o          : out std_logic;
            i2c_ena_o       : out std_logic;
            i2c_addr_o      : out std_logic_vector (6 downto 0);
            i2c_rw_o        : out std_logic;
            i2c_data_wr_o   : out std_logic_vector(7 downto 0);
            i2c_busy_i      : in  std_logic;
            i2c_ack_error_i : in  std_logic
        );
    end component ssm2603_config;

    signal reset_hard_n : std_logic;

    -- Audio CODEC signals
    signal ena_aud_config     : std_logic;
    signal busy_aud_config     : std_logic;
    signal aud_config_i2c_ena     : std_logic := '0';
    signal aud_config_i2c_addr    : std_logic_vector(6 downto 0) := "0011011"; -- 0x1B (0x36 write address)
    signal aud_config_i2c_rw      : std_logic := '0';
    signal aud_config_i2c_data_wr : std_logic_vector(7 downto 0) := (others => '0');

    -- I2C Master Control Signals
    signal i2c_ena     : std_logic := '0';
    signal i2c_addr    : std_logic_vector(6 downto 0) := "0011011"; -- 0x1B (0x36 write address)
    signal i2c_rw      : std_logic := '0';
    signal i2c_data_wr : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_data_rd : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_busy    : std_logic;
    signal i2c_ack_error    : std_logic;

    signal i2c_data_rd_o : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_busy_o    : std_logic;
    signal i2c_ack_error_o    : std_logic;

    
    -- codec config FSM States
    type state_type is (INIT, AUD_CODEC_CONFIG, ACTIVE);
    signal state : state_type := INIT;
begin

    -------------------------------------------------------------------
    -- 1. CLOCK GENERATION
    -------------------------------------------------------------------
    AUD_XCK <= clk_aud;

    -------------------------------------------------------------------
    -- 2. DIGITAL AUDIO LOOPBACK
    -------------------------------------------------------------------
    AUD_DACDAT <= AUD_ADCDAT; -- given every 

    -------------------------------------------------------------------
    -- 3. AUD CODEC CONFIGURATION CONTROLLER
    -------------------------------------------------------------------
    ssm2603_config_inst : ssm2603_config
        generic map(
            G_INPUT_CLK => G_INPUT_CLK,
            G_DEVICE_ADDR => 16#36#
        )
        port map(
            clk             => clk,
            rst_n           => reset_hard_n,
            ena_i           => ena_aud_config, -- block enabled; runs ones
            busy_o          => busy_aud_config, -- busy configurating;

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
        i2c_ena     <= '0';
        i2c_addr    <= (others => '0');
        i2c_rw      <= '0';
        i2c_data_wr <= (others => '0');
        i2c_data_rd <= (others => '0');
        i2c_busy <= '0';
        i2c_ack_error <= '0';

        case state is
            when AUD_CODEC_CONFIG => 
                i2c_ena     <= aud_config_i2c_ena;
                i2c_addr    <= aud_config_i2c_addr;
                i2c_rw      <= aud_config_i2c_rw;
                i2c_data_wr <= aud_config_i2c_data_wr;
                i2c_data_rd <= i2c_data_rd_o;
                i2c_busy <= i2c_busy_o;
                i2c_ack_error <= i2c_ack_error_o;    
            when others =>
        end case;
    end process i2c_mux;
    
    name : process (clk) is
    begin
        if rising_edge(clk) then
            if reset_hard_n = '0' then
                ena_aud_config <= '0';
                state <= INIT;
            else
                case state is
                    when INIT => 
                        state <= AUD_CODEC_CONFIG;
                        ena_aud_config <= '0';
                    when AUD_CODEC_CONFIG =>
                        ena_aud_config <= '1';
                        if (ena_aud_config = '1' and busy_aud_config = '0') then
                            state <= ACTIVE;
                        end if;
                    when ACTIVE =>
                        ena_aud_config <= '0';
                        state <= ACTIVE;
                    when others => 
                        ena_aud_config <= '0';
                        state <= INIT;
                end case;
            end if;
        end if;
    end process name;
    

    i2c_master_inst : i2c_master
        generic map (
            G_INPUT_CLK => G_INPUT_CLK,
            G_BUS_CLK   => G_AUD_CLK
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
            sda_io       => FPGA_I2C_SDA,
            scl_io       => FPGA_I2C_SCL
        );

    reset_hard_n <= reset_n and not(i2c_ack_error);

end rtl;