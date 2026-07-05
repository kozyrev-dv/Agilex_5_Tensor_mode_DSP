`timescale 1ns / 1ns

module i2c_slave_model #(
    parameter bit [6:0] SLAVE_ADDR = 7'h36
) (
    inout wire sda,
    inout wire scl
);

  logic sda_out;
  logic sda_en;
  logic [7:0] shift_reg;
  logic [7:0] mem_data = 8'hA5;  // Dummy data

  assign sda = (sda_en && sda_out == 1'b0) ? 1'b0 : 1'bz;

  // I2C Events
  event e_start;
  event e_stop;

  // START - SDA goes low while SCL is high
  always @(negedge sda) begin
    if (scl === 1'b1)->e_start;
  end

  // STOP - SDA goes high while SCL is high
  always @(posedge sda) begin
    if (scl === 1'b1)->e_stop;
  end

  // Main I2C FSM
  initial begin
    sda_en  = 0;
    sda_out = 0;

    forever begin
      @e_start;  // Wait for a START condition
      handle_transaction();
    end
  end

  task handle_transaction();
    bit [6:0] addr;
    bit rw;
    bit ack_rx;

    fork : transaction_threads
      begin
        // 1. Receive Address + R/W bit
        receive_byte(shift_reg);
        addr = shift_reg[7:1];
        rw   = shift_reg[0];

        // 2. Check if the master is talking to us
        if (addr !== SLAVE_ADDR) begin
          wait (0);  // Not our address. Suspend this thread until killed by join_any
        end

        // 3. Send ACK for matching address
        send_ack();

        // 4. Process Read or Write
        if (rw == 1'b0) begin
          $display("[%0t] I2C Slave (0x%h): Addressed for WRITE", $time, addr);
          forever begin
            receive_byte(shift_reg);
            $display("[%0t] I2C Slave: Received Data = 0x%h", $time, shift_reg);
            send_ack();
          end
        end else begin
          $display("[%0t] I2C Slave (0x%h): Addressed for READ", $time, addr);
          forever begin
            send_byte(mem_data);
            receive_ack(ack_rx);

            $display("[%0t] I2C Slave: Sent Data = 0x%h", $time, mem_data);
            mem_data++;  // Increment dummy data for the next read request

            if (ack_rx) begin
              $display("[%0t] I2C Slave: Master NACKed, ending read.", $time);
              break;
            end
          end
        end
      end

      // Abort conditions
      begin
        @e_stop;
        $display("[%0t] I2C Slave: STOP condition detected.", $time);
      end
      begin
        #(1ps);  // Micro-delay to avoid catching the current start event
        @e_start;
        $display("[%0t] I2C Slave: Repeated START condition detected.", $time);
      end
    join_any

    // Kill all active threads in this fork once any thread completes (e.g., STOP detected)
    disable fork;
    sda_en = 1'b0;  // Release bus
  endtask

  // --- Low-Level Protocol Tasks ---

  task receive_byte(output logic [7:0] data);
    for (int i = 7; i >= 0; i--) begin
      @(posedge scl);
      data[i] = sda;
    end
  endtask

  task send_byte(input logic [7:0] data);
    for (int i = 7; i >= 0; i--) begin
      @(negedge scl);
      sda_out = data[i];
      sda_en  = 1'b1;
    end
    @(negedge scl);
    sda_en = 1'b0;  // Release SDA so master can ACK/NACK
  endtask

  task send_ack();
    @(negedge scl);
    sda_out = 1'b0;  // Pull low for ACK
    sda_en  = 1'b1;
    @(negedge scl);
    sda_en = 1'b0;  // Release SDA
  endtask

  task receive_ack(output bit nack);
    @(posedge scl);
    nack = sda;  // 0 = ACK, 1 = NACK
    @(negedge scl);
  endtask

endmodule
