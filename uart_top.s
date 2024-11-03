module uart_top
#(
  parameter clk_freq = 1000000,  // Clock frequency in Hz (default: 1 MHz)
  parameter baud_rate = 9600     // UART baud rate (default: 9600 bps)
)
(
  input clk, rst,                // System clock and reset
  input rx,                      // UART receive line
  input [7:0] dintx,             // Data input for transmission
  input newd,                    // Signal indicating new data to transmit
  output tx,                     // UART transmit line
  output [7:0] doutrx,           // Data output from reception
  output donetx,                 // Transmission complete signal
  output donerx                  // Reception complete signal
);

// Instantiate the UART transmitter module
uarttx
#(
  .clk_freq(clk_freq),
  .baud_rate(baud_rate)
)
utx
(
  .clk(clk),
  .rst(rst),
  .newd(newd),
  .tx_data(dintx),
  .tx(tx),
  .donetx(donetx)
);

// Instantiate the UART receiver module
uartrx
#(
  .clk_freq(clk_freq),
  .baud_rate(baud_rate)
)
rtx
(
  .clk(clk),
  .rst(rst),
  .rx(rx),
  .done(donerx),
  .rxdata(doutrx)
);

endmodule
