`define CLK_PERIOD 1_000_000_000 / 50_000_000
`define CLK_AUD_PERIOD 1_000_000_000 / 12_288_000
`timescale 1ns/1ns

module audio_process_top_tb();
    parameter int G_INPUT_CLK_HZ = 50_000_000;
    parameter int G_AUD_CLK_HZ   = 12_288_000;
    parameter int G_AUD_CONFIG_DELAY_US = 10;

    logic clk = 0;
    logic clk_aud = 0;
    logic reset_n;

    // I2C interface lines
    wire FPGA_I2C_SCL;
    wire FPGA_I2C_SDA;

    // Audio Codec Interface signals
    wire AUD_XCK;
    wire AUD_BCLK;
    wire AUD_ADCLRCK;
    logic AUD_ADCDAT = 0;
    wire AUD_DACLRCK;
    wire AUD_DACDAT;

    i2c_slave_model #(
        .SLAVE_ADDR(7'h36) // Set to match your Codec Address
    ) slave_inst (
        .sda(FPGA_I2C_SDA),
        .scl(FPGA_I2C_SCL)
    );

    pullup (FPGA_I2C_SCL);
    pullup (FPGA_I2C_SDA);

    audio_process_top #(
        .G_INPUT_CLK_HZ(G_INPUT_CLK_HZ),
        .G_AUD_CLK_HZ(G_AUD_CLK_HZ),
        .G_AUD_CONFIG_DELAY_US(G_AUD_CONFIG_DELAY_US)
    ) dut (
        .clk(clk),
        .clk_aud(clk_aud),
        .reset_n(reset_n),
        .FPGA_I2C_SCL(FPGA_I2C_SCL),
        .FPGA_I2C_SDA(FPGA_I2C_SDA),
        .AUD_XCK(AUD_XCK),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_ADCDAT(AUD_ADCDAT),
        .AUD_DACLRCK(AUD_DACLRCK),
        .AUD_DACDAT(AUD_DACDAT)
    );

    always #(`CLK_PERIOD / 2.0) clk = ~clk;
    always #(`CLK_AUD_PERIOD / 2.0) clk_aud = ~clk_aud;

    always @(posedge AUD_BCLK) begin
        if (!reset_n) begin
            AUD_ADCDAT <= 1'b0;
        end else begin
            AUD_ADCDAT <= $random;
        end
    end

    initial begin
        $display("[%0t ns] Simulation started.", $time);
        $display("System Clock: %0d Hz (Period: %0f ns)", G_INPUT_CLK_HZ, `CLK_PERIOD);
        $display("Audio Clock:  %0d Hz (Period: %0f ns)", G_AUD_CLK_HZ, `CLK_AUD_PERIOD);

        reset_n = 1'b0;
        #(`CLK_PERIOD * 10);

        $display("[%0t ns] Releasing Reset. Initializing Codec configuration via I2C...", $time);
        reset_n = 1'b1;

        #(`CLK_PERIOD * 100_000);

        
        $display("[%0t ns] Simulation execution completed", $time);
        $stop;
    end


    initial begin
        #(10_000_000);
        $stop;
    end
    

endmodule
