// Listing 16.3
module pico_sio
   (
    input wire clk, reset,
    input wire [7:0] sw,
    output wire [7:0] led
   );

   // signal declaration
   // KCPSM3/ROM signals
   wire [9:0] address;
   wire [17:0] instruction;
   wire [7:0] port_id, in_port, out_port;
   wire  write_strobe;
   // register signals
   reg [7:0] led_reg;

   //body
   // =====================================================
   //  KCPSM and ROM instantiation
   // =====================================================
   kcpsm3 proc_unit
      (.clk(clk), .reset(reset), .address(address),
       .instruction(instruction), .port_id(),
       .write_strobe(write_strobe), .out_port(out_port),
       .read_strobe(), .in_port(in_port), .interrupt(1'b0),
       .interrupt_ack());
   sio_rom rom_unit
      (.clk(clk), .address(address),
       .instruction(instruction));
   // =====================================================
   //  output interface
   // =====================================================
   always @(posedge clk)
      if (write_strobe)
         led_reg <= out_port;
   assign led = led_reg;
   // =====================================================
   //  input interface
   // =====================================================
   assign in_port = sw;

endmodule
