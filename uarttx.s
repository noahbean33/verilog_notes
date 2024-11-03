module uarttx
#(
  parameter clk_freq = 1000000,  // Clock frequency in Hz
  parameter baud_rate = 9600     // UART baud rate
)
(
  input clk, rst,                // System clock and reset
  input newd,                    // New data signal
  input [7:0] tx_data,           // Data to transmit
  output reg tx,                 // UART transmit line
  output reg donetx              // Transmission complete signal
);

localparam clkcount = (clk_freq / baud_rate);  // Clock cycles per baud period

reg [15:0] count = 0;            // Baud rate clock divider counter
reg [3:0] counts = 0;            // Bit transmission counter
reg uclk = 0;                    // Baud rate clock
reg [7:0] din;                   // Internal data register

// State encoding for the state machine
typedef enum reg [1:0] {
  idle     = 2'b00,
  start    = 2'b01,
  transfer = 2'b10,
  stop     = 2'b11
} state_t;

state_t state;

// Baud rate clock generation
always @(posedge clk or posedge rst) begin
  if (rst) begin
    count <= 0;
    uclk <= 0;
  end else if (count < (clkcount / 2 - 1)) begin
    count <= count + 1;
  end else begin
    count <= 0;
    uclk <= ~uclk;  // Toggle baud rate clock
  end
end

// UART transmit state machine
always @(posedge uclk or posedge rst) begin
  if (rst) begin
    state <= idle;
    tx <= 1'b1;     // UART idle state is high
    donetx <= 1'b0;
    counts <= 0;
    din <= 8'b0;
  end else begin
    case (state)
      idle: begin
        tx <= 1'b1;
        donetx <= 1'b0;
        if (newd) begin
          din <= tx_data;
          state <= start;
        end
      end

      start: begin
        tx <= 1'b0;  // Start bit
        state <= transfer;
        counts <= 0;
      end

      transfer: begin
        tx <= din[counts];  // Transmit data bits LSB first
        if (counts < 7) begin
          counts <= counts + 1;
        end else begin
          counts <= 0;
          state <= stop;
        end
      end

      stop: begin
        tx <= 1'b1;   // Stop bit
        donetx <= 1'b1;
        state <= idle;
      end

      default: state <= idle;
    endcase
  end
end

endmodule
