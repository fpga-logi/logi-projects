// Listing 12.1
// Single-port RAM with asynchronous read
// Modified from XST 8.1i v_rams_04

module xilinx_one_port_ram_async
   #(
     parameter ADDR_WIDTH = 8,
               DATA_WIDTH = 1
   )
   (
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
   );

   // signal declaration
   reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];

   // body
   always @(posedge clk)
      if (we)  // write operation
         ram[addr] <= din;
   // read operation
   assign dout = ram[addr];

endmodule
