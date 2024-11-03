`timescale 1ns / 1ps

module uart_tb;
  reg clk;
  reg rst;
  reg rx;
  reg [7:0] dintx;
  reg newd;
  wire tx;
  wire [7:0] doutrx;
  wire donetx;
  wire donerx;

  // Instantiate the UART top module with parameters (1 MHz clock, 9600 baud rate)
  uart_top #(1000000, 9600) dut (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .dintx(dintx),
    .newd(newd),
    .tx(tx),
    .doutrx(doutrx),
    .donetx(donetx),
    .donerx(donerx)
  );

  // Clock generation (1 MHz clock => period of 1000 ns)
  always #500 clk = ~clk;  // Toggle every 500 ns to get 1 MHz clock

  // Timing parameters
  real baud_period = 1e9 / 9600;  // Baud rate period in nanoseconds (approx 104166.67 ns)

  initial begin
    // Initialize signals
    clk = 0;
    rst = 1;
    rx = 1;
    dintx = 8'b0;
    newd = 0;
    #2000;  // Wait for 2 μs (reset duration)
    rst = 0;

    // Transmit data loop
    for (int i = 0; i < 10; i++) begin
      dintx = $urandom % 256;  // Generate random 8-bit data
      tx_data = dintx;
      newd = 1;
      @(posedge clk);
      newd = 0;

      // Wait for transmission to complete
      wait (donetx == 1);

      // Capture transmitted data by monitoring the tx line
      capture_tx_data();

      // Verify transmitted data
      if (tx_data != dintx) begin
        $display("Error: Transmitted data mismatch at time %t ns. Expected: %h, Got: %h", $time, dintx, tx_data);
      end else begin
        $display("Success: Data transmitted correctly at time %t ns. Data: %h", $time, tx_data);
      end
    end

    // Receive data loop
    for (int i = 0; i < 10; i++) begin
      rx_data = $urandom % 256;  // Generate random 8-bit data
      uart_send_byte(rx_data);

      // Wait for reception to complete
      wait (donerx == 1);

      // Verify received data
      if (doutrx != rx_data) begin
        $display("Error: Received data mismatch at time %t ns. Expected: %h, Got: %h", $time, rx_data, doutrx);
      end else begin
        $display("Success: Data received correctly at time %t ns. Data: %h", $time, doutrx);
      end
    end

    $finish;  // End simulation
  end

  // Task to capture transmitted data from tx line
  task capture_tx_data;
    integer i;
    begin
      tx_data = 8'b0;
      // Wait for start bit
      wait (tx == 0);
      #(baud_period);  // Wait for middle of start bit

      // Capture 8 data bits
      for (i = 0; i < 8; i = i + 1) begin
        #(baud_period);
        tx_data = {tx, tx_data[7:1]};  // Shift in the tx bit
      end

      // Wait for stop bit
      #(baud_period);
    end
  endtask

  // Task to simulate UART reception by driving the rx line
  task uart_send_byte(input [7:0] data);
    integer i;
    begin
      rx = 0;  // Start bit
      #(baud_period);

      // Send 8 data bits (LSB first)
      for (i = 0; i < 8; i = i + 1) begin
        rx = data[i];
        #(baud_period);
      end

      rx = 1;  // Stop bit
      #(baud_period);
    end
  endtask

endmodule
