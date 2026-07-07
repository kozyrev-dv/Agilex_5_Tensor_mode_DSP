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

    type   lr_logic_t is array (0 to 1) of std_logic;
    type   lr_dat_t is array (0 to 1) of std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    type   lr_cnt_t is array (0 to 1) of integer range 0 to G_DATA_WIDTH - 1;
    signal dat_lr_o    : lr_logic_t;
    signal dat_lr_reg  : lr_dat_t;
    signal dat_lr_busy : lr_logic_t;
    signal cnt_lr      : lr_cnt_t;

    signal 
    signal dat_reg : std_logic_vector(G_DATA_WIDTH - 1 downto 0);
    
    signal lrc_prev  : std_logic;
    signal bclk_prev : std_logic;

    type     lt_match_array_y is array (0 to 1) of std_logic;
    constant LT_I_TARGET : lt_match_array_y := ('0', '1');
begin

    sig_watcher_p : process (clk_i) is
    begin
        if (rising_edge(clk_i)) then
            if (reset_n_i = '0') then
                bclk_prev <= '0';
                lrc_prev  <= '0';
            else
                bclk_prev <= bclk_i;
                lrc_prev  <= lrc_i;
            end if;
        end if;
    end process sig_watcher_p;

    dat_o         <= dat_lr_o(0) when lrc_i = '0' else
                     dat_lr_o(1);
    dat_tx_busy_o <= '1' when (dat_lr_busy(0) = '1' and lrc_i = '0') or
                              (dat_lr_busy(1) = '1' and lrc_i = '1') else
                     '0';
    
    -- TODO: data must be outputed only with start of the channel on lrc_i!
    --

    generate_lr_shift_regs : for ii in 0 to 1 generate -- '0' is for left and '1' is for right
        dat_lr_o(ii) <= dat_lr_reg(ii)(dat_lr_reg(ii)'high);

        dat_lr_reg_ctrl_p : process (clk_i) is
        begin
            if (rising_edge(clk_i)) then
                if (reset_n_i = '0') then
                    dat_lr_reg(ii)  <= (others => '0');
                    dat_lr_busy(ii) <= '0';
                    cnt_lr(ii)      <= 0;
                else
                    -- load in NOT busy respective reg
                    if (dat_tx_valid_i = '1' and dat_lr_busy(ii) = '0' and dat_tx_lr_i = LT_I_TARGET(ii)) then
                        dat_lr_reg(ii)  <= dat_tx_i;
                        dat_lr_busy(ii) <= '1';
                        cnt_lr(ii)      <= G_DATA_WIDTH - 1;
                    -- prepare data for i2s rx to latch on negedge bclk. Shifting ONLY when correct lr channel selected
                    elsif (bclk_prev = '1' and bclk_i = '0' and lrc_i = LT_I_TARGET(ii)) then
                        dat_lr_reg(ii) <= dat_lr_reg(ii)(dat_lr_reg(ii)'high - 1 downto dat_lr_reg(ii)'low) & '0';
                        -- keep busy while there's something to shift
                        if (cnt_lr(ii) = 0) then
                            dat_lr_busy(ii) <= '0';
                        else
                            cnt_lr(ii)      <= cnt_lr(ii) - 1;
                            dat_lr_busy(ii) <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end process dat_lr_reg_ctrl_p;
    end generate generate_lr_shift_regs;

end architecture rtl;
