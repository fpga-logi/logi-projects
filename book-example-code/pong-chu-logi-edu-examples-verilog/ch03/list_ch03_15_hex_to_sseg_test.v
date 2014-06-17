// Listing 3.15
//--******************************************************************
//-- Notes to run on logi:
//-- * uses sw(1:0) & btn(1:0) as 4 bits to be displayed on the 4x sseg dispaly.
//-- * The inc value increments the 4 bit value by 1 and displays this.
//--*******************************************************************/
module hex_to_sseg_test
   (
     input wire clk,
     input wire [1:0] sw_n, btn_n,
     output wire [3:0] an,
     output wire [7:0] sseg
   );

   // signal declaration
   wire [7:0] inc;
   wire [7:0] led0, led1, led2, led3;
	wire [1:0] sw, btn;
	wire [3:0] hex;
	

	assign sw = ~(sw_n);
	assign btn = ~(btn_n);
	
	
	//assign hex value from sw and buttons
	assign hex = {sw[1:0], btn[1:0]};
   // increment input
   assign inc = hex + 1;

   // instantiate four instances of hex decoders
   // instance for 4 LSBs of input
   hex_to_sseg sseg_unit_0
      (.hex( hex), .dp(1'b0), .sseg(led0));
   // instance for 4 MSBs of input
   hex_to_sseg sseg_unit_1
      (.hex(hex), .dp(1'b0), .sseg(led1));
   // instance for 4 LSBs of incremented value
   hex_to_sseg sseg_unit_2
      (.hex(inc[3:0]), .dp(1'b1), .sseg(led2));
   // instance for 4 MSBs of incremented value
   hex_to_sseg sseg_unit_3
      (.hex(inc[3:0]), .dp(1'b1), .sseg(led3));

   // instantiate 7-seg LED display time-multiplexing module
   disp_mux disp_unit
      (.clk(clk), .reset(1'b0), .in0(led0), .in1(led1),
       .in2(led2), .in3(led3), .an(an), .sseg(sseg));

endmodule