// Listing 4.19
module stop_watch_test
   (
    input wire clk,
    input wire [1:0] btn_n,
    output wire [3:0] an,
    output wire [7:0] sseg
   );

   // signal declaration
   wire [3:0]  d2, d1, d0;
	wire [1:0] btn;
	
	assign btn = ~btn_n;
   // instantiate 7-seg LED display module
   disp_hex_mux disp_unit
      (.clk(clk), .reset(1'b0),
       .hex3(4'b0), .hex2(d2), .hex1(d1), .hex0(d0),
       .dp_in(4'b1101), .an(an), .sseg(sseg));

   // instantiate stopwatch
   stop_watch_if counter_unit
      (.clk(clk), .go(btn[1]), .clr(btn[0]),
       .d2(d2), .d1(d1), .d0(d0) );

endmodule
