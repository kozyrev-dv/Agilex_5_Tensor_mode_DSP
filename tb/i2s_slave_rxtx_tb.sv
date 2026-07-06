`timescale 1ns/1ns

module i2s_slave_rxtx_tb();
    localparam integer CLK_FREQ_HZ = 50_000_000;
    localparam integer MCLK_FREQ_HZ = 12_288_000;
    localparam integer RECDATA_WIDTH = 32;
    localparam integer PBDATA_WIDTH = 32;

    specparam CLK_PERIOD  = 1_000_000_000 / CLK_FREQ_HZ; 
    specparam MCLK_PERIOD = 1_000_000_000 / MCLK_FREQ_HZ;

    bit clk_i = '0;
    bit reset_n_i = '1;
    bit mclk_i = '0;

    bit i2s_bclk_tx_out;
    bit i2s_recdat_tx_out;
    bit i2s_reclr_tx_out;
    bit [RECDATA_WIDTH - 1 : 0] dat_rx_out;
    bit dat_rx_lr_out;
    bit dat_rx_valid_out;

    bit i2s_bclk_rx_in;
    bit i2s_pbdat_rx_in;
    bit i2s_pblr_rx_in;
    bit [PBDATA_WIDTH - 1 : 0] dat_tx_in;
    bit dat_tx_lr_in;
    bit dat_tx_valid_in;

    i2s_master_tx_model # (
        .MCLK_FREQ_HZ(MCLK_FREQ_HZ),
        .AUD_DATA_WIDTH(RECDATA_WIDTH)
    )
    i2s_master_tx_model_inst (
        .mclk_i(mclk_i),
        .reset_n_i(reset_n_i),
        .bclk_o(i2s_bclk_tx_out),
        .recdat_o(i2s_recdat_tx_out),
        .reclr_o(i2s_reclr_tx_out)
    );

    i2s_slave_rxtx # (
        .G_INPUT_CLK_HZ(CLK_FREQ_HZ),
        .G_DATA_WIDTH_RX(RECDATA_WIDTH),
        .G_DATA_WIDTH_TX(PBDATA_WIDTH)
    )
    i2s_slave_rxtx_inst (
        .clk_i(clk_i),
        .reset_n_i(reset_n_i),
        .i2s_bclk_i(i2s_bclk_tx_out),
        .i2s_lrc_rx_i(i2s_reclr_tx_out),
        .i2s_dat_rx_i(i2s_recdat_tx_out),
        .i2s_lrc_tx_o(i2s_pblr_rx_in),
        .i2s_dat_tx_o(i2s_pbdat_rx_in),
        .dat_rx_o(dat_rx_out),
        .dat_rx_lr_o(dat_rx_lr_out),
        .dat_rx_valid_o(dat_rx_valid_out),
        .dat_tx_i(dat_tx_in),
        .dat_tx_lr_i(dat_tx_lr_in),
        .dat_tx_valid_i(dat_tx_valid_in)
    );

    initial begin
        mclk_i = '0;
        clk_i = '0;
        fork
            forever begin
                mclk_i = #(MCLK_PERIOD / 2) ~mclk_i;
            end
            forever begin
                clk_i = #(CLK_PERIOD / 2) ~clk_i;
            end
        join_none
    end

    initial begin
        #(MCLK_PERIOD * 160);
        reset_n_i = '0;
        #(MCLK_PERIOD * 50);
        reset_n_i = '1;
        #(MCLK_PERIOD * 100_0);
        $stop;
    end


endmodule