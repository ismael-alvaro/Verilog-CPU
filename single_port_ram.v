module single_port_ram
(
  input [15:0] data,
  input [3:0] addr,
  input we, clk, reset,
  output reg [15:0] q
);

// Declare the RAM variable
reg [15:0] ram[15:0];

// Variable to hold the registered read address
reg [3:0] addr_reg; // 2^4=16

integer i;
initial begin     for (i = 0; i < 16; i = i + 1)
      ram[i] <= 16'b0000000000000000; end
		
always @ (posedge clk)
begin
  // Write
  if (we) 
    ram[addr] <= data;

  // Reset
  if (reset) begin
    for (i = 0; i < 16; i = i + 1)
      ram[i] <= 16'b0000000000000000;
    addr_reg <= 4'b0000;
  end
  
  addr_reg <= addr;
  q <= ram[addr_reg];
end

// Continuous assignment implies read returns NEW data.
// This is the natural behavior of the TriMatrix memory
// blocks in Single Port mode.

endmodule
