module uartrx
#(
  parameter clk_freq = 1000000,  // Clock frequency in Hz
  parameter baud_rate = 9600     // UART baud rate
)
(
  input clk,
  input rst,
  input rx,                      // UART receive line
  output reg done,               // Reception complete signal
  output reg [7:0] rxdata        // Received data
);

localparam clkcount = (clk_freq / baud_rate);  // Clock cycles per baud period

reg [15:0] count = 0;            // Baud rate clock divider counter
reg [3:0] counts = 0;            // Bit reception counter
reg uclk = 0;                    // Baud rate clock

// State encoding for the state machine
typedef enum reg [1:0] {
  idle  = 2'b00,
  start = 2'b01,
  data  = 2'b10,
  stop  = 2'b11
} state_t;

state_t state;

// Baud rate clock generation
always @(posedge clk or posedge rst) begin
  if (rst) begin
    count <= 0;
    uclk <= 0;
  end else if (count < (clkcount - 1)) begin
    count <= count + 1;
  end else begin
    count <= 0;
    uclk <= ~uclk;  // Toggle baud rate clock
  end
end

// UART receive state machine
always @(posedge uclk or posedge rst) begin
  if (rst) begin
    state <= idle;
    rxdata <= 8'h00;
    counts <= 0;
    done <= 1'b0;
  end else begin
    case (state)
      idle: begin
        done <= 1'b0;
        if (rx == 1'b0) begin  // Detect start bit
          state <= start;
          counts <= 0;
        end
      end

      start: begin
        if (counts == (clkcount / 2)) begin  // Sample in the middle of the bit period
          state <= data;
          counts <= 0;
        end else begin
          counts <= counts + 1;
        end
      end

      data: begin
        rxdata <= {rx, rxdata[7:1]};  // Shift in received bits LSB first
        if (counts < 7) begin
          counts <= counts + 1;
        end else begin
          counts <= 0;
          state <= stop;
        end
      end

      stop: begin
        if (rx == 1'b1) begin  // Check for valid stop bit
          done <= 1'b1;        // Reception successful
        end
        state <= idle;
      end

      default: state <= idle;
    endcase
  end
end

endmodule
