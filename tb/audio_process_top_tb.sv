`define CLK_PERIOD 1_000_000_000 / 50_000_000
`define CLK_AUD_PERIOD 1_000_000_000 / 12_288_000
`timescale 1ns/1ns

module audio_process_top_tb();
    // --- Parameter Definitions ---
    parameter int G_INPUT_CLK = 50_000_000;
    parameter int G_AUD_CLK   = 12_288_000;

    // --- Testbench Signals ---
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

    // 2. Instantiate the SystemVerilog Slave
    i2c_slave_model #(
        .SLAVE_ADDR(7'h36) // Set to match your Codec Address
    ) slave_inst (
        .sda(FPGA_I2C_SDA),
        .scl(FPGA_I2C_SCL)
    );

    // --- Pull-up Emulation for I2C (Open-Drain Bus) ---
    // In SystemVerilog, a 'pullup' primitive properly simulates external 
    // resistors, pulling the bus High ('H') when the master releases it.
    pullup (FPGA_I2C_SCL);
    pullup (FPGA_I2C_SDA);

    // --- Device Under Test (DUT) Instantiation ---
    // Connects directly to the VHDL design (mixed-language simulation support)
    audio_process_top #(
        .G_INPUT_CLK(G_INPUT_CLK),
        .G_AUD_CLK(G_AUD_CLK)
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

    // --- Clock Generation ---
    // 50 MHz System Clock
    always #(`CLK_PERIOD / 2.0) clk = ~clk;

    // 12.288 MHz Audio Clock Sourced from External PLL
    always #(`CLK_AUD_PERIOD / 2.0) clk_aud = ~clk_aud;

    // --- Dummy Serial Data Feeding (I2S simulation) ---
    // Generates walking 1s and 0s synchronous to the BCLK edge 
    // to verify that the loopback paths are passing data.
    always @(posedge AUD_BCLK) begin
        if (!reset_n) begin
            AUD_ADCDAT <= 1'b0;
        end else begin
            AUD_ADCDAT <= $random; // Feeds randomized audio bitstream streams
        end
    end

    // --- Test Vector Sequence ---
    initial begin
        // Display initial header configuration details
        $display("[%0t ns] Simulation started.", $time);
        $display("System Clock: %0d Hz (Period: %0f ns)", G_INPUT_CLK, `CLK_PERIOD * 1e9);
        $display("Audio Clock:  %0d Hz (Period: %0f ns)", G_AUD_CLK, `CLK_AUD_PERIOD * 1e9);
        
        // 1. Initial State: Hold module in Hard Reset
        reset_n = 1'b0;
        #(`CLK_PERIOD * 10);
        
        // 2. Release Reset: State Machine transitions from INIT to AUD_CODEC_CONFIG
        $display("[%0t ns] Releasing Reset. Initializing Codec configuration via I2C...", $time);
        reset_n = 1'b1;

        // 3. Let it execute. Monitor line transitions.
        // The ssm2603_config module will dispatch 8 registers over the I2C interface.
        // At 400kHz I2C bus speeds, this process will take several milliseconds in hardware.
        // Adjust the wait window delay according to your simulation optimizations.
        #(`CLK_PERIOD * 100_000); 

        // 4. End Simulation gracefully
        $display("[%0t ns] Simulation execution completed", $time);
        $stop;
    end


    initial begin
        #(10_000_000);
        $stop;
    end
    

endmodule
