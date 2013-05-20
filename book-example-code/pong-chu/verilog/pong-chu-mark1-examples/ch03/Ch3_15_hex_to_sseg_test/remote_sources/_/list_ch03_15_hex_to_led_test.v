// Listing 3.15
/******************************************************************
* Port to Mark1 Notes: 
*******************************************************************/
module hex_to_sseg_test
   (
     input wire clk,
     input wire [7:0] sw,
     output wire [3:0] an,
     output wire [7:0] sseg
   );

   // signal declaration
   wire [7:0] inc;
   wire [7:0] led0, led1, led2, led3;

   // increment input
   assign inc = sw + 1;

   // instantiate four instances of hex decoders
   // instance for 4 LSBs of input
   hex_to_sseg sseg_unit_0
      (.hex(sw[3:0]), .dp(1'b0), .sseg(led0));
   // instance for 4 MSBs of input
   hex_to_sseg sseg_unit_1
      (.hex(sw[7:4]), .dp(1'b0), .sseg(led1));
   // instance for 4 LSBs of incremented value
   hex_to_sseg sseg_unit_2
      (.hex(inc[3:0]), .dp(1'b1), .sseg(led2));
   // instance for 4 MSBs of incremented value
   hex_to_sseg sseg_unit_3
      (.hex(inc[7:4]), .dp(1'b1), .sseg(led3));

   // instantiate 7-seg LED display time-multiplexing module
   disp_mux disp_unit
      (.clk(clk), .reset(1'b0), .in0(led0), .in1(led1),
       .in2(led2), .in3(led3), .an(an), .sseg(sseg));

endmodule