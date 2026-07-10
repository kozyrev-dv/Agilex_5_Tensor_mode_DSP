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

        dat_tx_i         : in    std_logic_vector(G_DATA_WIDTH - 1 downto 0);
        dat_tx_lr_i      : in    std_logic;
        dat_tx_valid_i   : in    std_logic;
        dat_tx_l_empty_o : out   std_logic := '1';
        dat_tx_r_empty_o : out   std_logic := '1'
    );
end entity i2s_slave_tx;

architecture rtl of i2s_slave_tx is

    signal dat_l_reg : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal dat_r_reg : std_logic_vector(G_DATA_WIDTH - 1 downto 0);

    signal lrc_d1       : std_logic := '0';
    signal lrc_d2       : std_logic := '0';
    signal bclk_prev    : std_logic := '0';
    signal bclk_negedge : std_logic := '0';

    signal shift_reg_dat_preload : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal shift_reg_dat         : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    signal shift_reg_load_pulse  : std_logic;
    signal shift_reg_cnt         : integer range 0 to G_DATA_WIDTH - 1;
begin

    sig_watcher_p : process (clk_i) is
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then
                bclk_prev    <= '0';
                bclk_negedge <= '0';
                lrc_d1       <= '0';
                lrc_d2       <= '0';
            else
                bclk_prev    <= bclk_i;
                bclk_negedge <= bclk_prev and not bclk_i;
                lrc_d1       <= lrc_i;
                lrc_d2       <= lrc_d1;
            end if;
        end if;
    end process sig_watcher_p;

    -- lrc_front_catch_p : process (clk_i) is
    -- begin
    --     if (rising_edge(clk_i)) then
    --         if (reset_n_i = '0') then
    --             lr_channel_start <= (others => '0');
    --         else
    --             lr_channel_start(0) <= lrc_d1 and not lrc_i;
    --             lr_channel_start(1) <= not lrc_d1 and     lrc_i;
    --         end if;
    --     end if;
    -- end process lrc_front_catch_p;

    dat_preload_p : process (clk_i) is
    begin
        if rising_edge(clk_i) then
            if (reset_n_i = '0') then
                dat_l_reg        <= (others => '0');
                dat_r_reg        <= (others => '0');
                dat_tx_l_empty_o <= '1';
                dat_tx_r_empty_o <= '1';
            else
                if (bclk_negedge = '1' and shift_reg_load_pulse = '1') then -- flush reg into shift reg
                    if (lrc_i = '0') then
                        dat_tx_l_empty_o <= '1';
                    else
                        dat_tx_r_empty_o <= '1';
                    end if;
                elsif (dat_tx_valid_i = '1') then
                    if (dat_tx_lr_i = '0' and dat_tx_l_empty_o = '1') then
                        dat_l_reg        <= dat_tx_i;
                        dat_tx_l_empty_o <= '0';
                    end if;
                    if (dat_tx_lr_i = '1' and dat_tx_r_empty_o = '1') then
                        dat_r_reg        <= dat_tx_i;
                        dat_tx_r_empty_o <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process dat_preload_p;

    
    shift_reg_dat_preload <= (dat_l_reg and not lrc_i) or (dat_r_reg and lrc_i);
    shift_reg_load_pulse  <= lrc_d1 xor lrc_d2;

    shift_reg_p : process (clk_i) is
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then
            else
                if (bclk_negedge = '1') then
                    if (shift_reg_load_pulse) then
                        shift_reg_dat <= shift_reg_dat_preload;
                    else
                        shift_reg_dat <= shift_reg_dat(shift_reg_dat'high - 1 downto shift_reg_dat'low) & '0';
                        if (shift_reg_cnt /= 0) then
                            shift_reg_cnt <= shift_reg_cnt - 1;
                        else
                            shift_reg_cnt <= shift_reg_cnt;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process shift_reg_p;

    dat_o_delay_p: process (clk_i)
    begin
        if rising_edge(clk_i) then
            if (reset_n_i = '0') then
                dat_o <= '0';
            else
                if (bclk_negedge = '1') then
                    dat_o <= shift_reg_dat(shift_reg_dat'high);
                end if;
            end if;
        end if;
    end process dat_o_delay_p;

end architecture rtl;
