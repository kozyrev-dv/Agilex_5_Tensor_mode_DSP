library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity i2s_slave_tx is
    generic (
        G_DATA_WIDTH : integer := 8
    );
    port (
        clk_i     : in    std_logic;
        reset_n_i : in    std_logic;

        bclk_i : in    std_logic;
        lrc_i  : in    std_logic;
        dat_o  : out   std_logic;

        dat_tx_i       : in    std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        dat_tx_lr_i    : in    std_logic;
        dat_tx_valid_i : in    std_logic;
        dat_tx_busy_o  : out   std_logic
    );
end entity i2s_slave_tx;

architecture rtl of i2s_slave_tx is

    signal dat_reg             : std_logic_vector(dat_tx_i'high downto dat_tx_i'low);
    signal dat_cnt             : integer range 0 to G_DATA_WIDTH - 1;
    signal lr_reg              : std_logic;
    signal transacting_channel : std_logic := '0'; 

    signal shift_en  : std_logic;
    signal bclk_prev : std_logic;
    signal lrc_prev  : std_logic;
begin

    shift_en <= '1' when transacting_channel = '1' and bclk_prev = '1' and bclk_i = '0' else
                '0';

    tx_condition_p : process (clk_i) is
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then
                bclk_prev           <= '0';
                lrc_prev            <= '0';
                transacting_channel <= '0';
            else
                bclk_prev <= bclk_i;
                if (bclk_prev = '1' and bclk_i = '0') then
                    lrc_prev <= lrc_i;
                    if (
                        (lrc_prev = '0' and lrc_i = '1' and lr_reg = '1') or -- awaited right channel started
                        (lrc_prev = '1' and lrc_i = '0' and lr_reg = '0')    -- awaited left  channel started
                    ) then
                        transacting_channel <= '1';
                    end if;
                    if (transacting_channel = '1' and (lrc_i /= lr_reg or dat_cnt = 0)) then
                        transacting_channel <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process tx_condition_p;

    shift_reg : process (clk_i) is
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then
                dat_reg <= (others => '0');
                lr_reg  <= '0';
            else
                if (dat_tx_valid_i = '1') then -- parallel load
                    dat_reg <= dat_tx_i;
                    lr_reg  <= dat_tx_lr_i;
                elsif (shift_en = '1') then
                    dat_reg <= dat_reg(dat_reg'high - 1 downto dat_reg'low) & '0';
                end if;
            end if;
        end if;
    end process shift_reg;

    tx_cnt_p : process (clk_i) is
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then
                dat_cnt       <= 0;
                dat_tx_busy_o <= '0';
            else
                if (dat_tx_valid_i) then
                    dat_tx_busy_o <= '1';
                    dat_cnt       <= G_DATA_WIDTH - 1;
                end if;

                if (shift_en = '1') then
                    if (dat_cnt /= 0) then
                        dat_cnt <= dat_cnt - 1;
                    else
                        dat_tx_busy_o <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process tx_cnt_p;

    dat_o <= dat_reg(dat_reg'high) and transacting_channel;
end architecture rtl;
