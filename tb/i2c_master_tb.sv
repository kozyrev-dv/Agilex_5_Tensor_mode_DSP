`define CLK_PERIOD 1
`timescale 1ns/1ns


module i2c_master_tb;

    // System Signals
    logic clk_i = 0;
    logic reset_n_i = 0;
    
    // I2C Bus Signals
    tri1 sda_io;
    tri1 scl_io;
    
    // Master Interface Signals
    logic ena_i = 0;
    logic [6:0] addr_i = 7'h36;
    logic rw_i = 0;
    logic [7:0] data_wr_i = 8'h00;
    logic busy_o;
    logic [7:0] data_rd_o;
    logic ack_error_o;

    // Generate 50 MHz clock
    always #(`CLK_PERIOD) clk_i = ~clk_i; 

    // 1. Instantiate your VHDL Master
    i2c_master #(
        .g_input_clk(160_000_000),
        .g_bus_clk(10_000_000)
    ) dut (
        .clk_i(clk_i),
        .reset_n_i(reset_n_i),
        .ena_i(ena_i),
        .addr_i(addr_i),
        .rw_i(rw_i),
        .data_wr_i(data_wr_i),
        .busy_o(busy_o),
        .data_rd_o(data_rd_o),
        .ack_error_o(ack_error_o),
        .sda_io(sda_io),
        .scl_io(scl_io)
    );
    // 2. Instantiate the SystemVerilog Slave
    i2c_slave_model #(
        .SLAVE_ADDR(7'h36) // Set to match your Codec Address
    ) slave_inst (
        .sda(sda_io),
        .scl(scl_io)
    );

    // 3. Test Sequence
    initial begin

        reset_n_i = 0;
        #(`CLK_PERIOD * 10);
        reset_n_i = 1;
        #(`CLK_PERIOD * 10);

        // --- Test a Write Transaction ---
        ena_i = 1;
        rw_i = 0;
        addr_i = 7'h36;
        data_wr_i = 8'hAA; // Test byte
        wait(busy_o == 1);
        wait(busy_o == 0); // Wait for master to finish
        wait(busy_o == 1);
        wait(busy_o == 0); // Wait for master to finish
        data_wr_i = 8'h77; // Test byte
        wait(busy_o == 1);
        wait(busy_o == 0); // Wait for master to finish
        ena_i = 0;
        #(`CLK_PERIOD * 100);
        $stop;
    end

    initial begin
        #(`CLK_PERIOD * 1500);
        $stop;
    end

endmodule