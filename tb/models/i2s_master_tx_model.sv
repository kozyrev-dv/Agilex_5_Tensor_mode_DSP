`timescale 1ns / 1ns

module i2s_master_tx_model #(
    parameter MCLK_FREQ_HZ = 12_288_000,
    parameter AUD_DATA_WIDTH = 24
) (
    input  bit mclk_i,
    input  bit reset_n_i,
    output bit bclk_o,
    output bit recdat_o,
    output bit reclr_o
);

    localparam BCLK_FREQ_HZ = MCLK_FREQ_HZ / 4;  // from SSM 2603 spec
    localparam RECLR_FREQ_HZ = MCLK_FREQ_HZ / 256;  // from SSM 2603 spec
    specparam BCLK_PERIOD_NS = 1_000_000_000 / BCLK_FREQ_HZ;
    specparam RECLR_PERIOD_NS = 1_000_000_000 / RECLR_FREQ_HZ;

    bit is_running;
    assign is_running = reset_n_i;

    task send_data(input bit [31:0] val);
        for (integer pointer = 31; pointer >= 0; pointer--) begin
            if (is_running) begin
                recdat_o = val[pointer];
            end
            @(negedge (bclk_o));
        end
    endtask

    bit [31:0] data;
    task run();
        bclk_o  = '0;
        reclr_o = '0;
        fork : streaming_fork
            forever begin : bclk_gen
                if (is_running) begin
                    #(BCLK_PERIOD_NS / 2) bclk_o = ~bclk_o;
                end
            end
            forever begin : reclr_gen
                if (is_running) begin
                    #(RECLR_PERIOD_NS / 2) reclr_o = ~reclr_o;
                end
            end
            forever begin
                data = $urandom();
                send_data({data[31: (31 - AUD_DATA_WIDTH + 1)], {(31 - AUD_DATA_WIDTH + 1){1'b0}}});
            end
            begin
                #(1ps);
                wait (is_running == '0);
            end
        join_any
        disable fork;
    endtask

    initial begin
        forever begin
            wait (is_running == '1) run();
        end
    end

endmodule
