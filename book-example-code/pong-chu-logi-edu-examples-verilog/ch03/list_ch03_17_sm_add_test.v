// Listing 3.17
//-- Notes to run on logi:
//--	* The default A and B values are 2.  The sw0/1 values are the - sign bits by defaulT
//--	* user can uncommnet option 2 to use the buttons to control bit0 of a and b.
//-- SSEG0 = A when buttons0/1 = "00" (default)
//-- SSEG0 = B when buttons0/1 = "01"
//-- SSEG0 = sum when buttons0/1 = "10" or "11"
//-- * exepriment by changing the a and b static values.
//--*******************************************************************/
module sm_add_test
   (
    input wire clk,
    input wire [1:0] btn_n, sw_n,
    output wire [3:0] an,
    output wire [7:0] sseg
   );

   // signal declaration
   wire [3:0] sum, mout, oct,a,b;
   wire [7:0] led3, led2, led1, led0;
	wire [1:0] btn, sw;


	assign btn = ~(btn_n);
	assign sw = ~(sw_n);
	//base value of 2 with switch with switch values negative bit3.
	//(COMMENT THIS IS RUNNING OPTION2)

	assign a = {sw[0], 3'b010};
	assign b = {sw[1], 3'b010};
	//-- OPTION2 (UNCOMMENT THIS IF WANT TO RUN)base value of 2 with switch with switch values = low bit. (+1)
	//assign a = {"010", {sw(0)};
	//assign b = {"010", {sw(1)};

   // instantiate adder
   sign_mag_add #(.N(4)) sm_adder_unit
     (.a(a), .b(b), .sum(sum));

   //  magnitude displayed on rightmost 7-seg LED
   assign mout = (btn==2'b00) ? a :
                 (btn==2'b01) ? b :
                 sum;
   assign oct = {1'b0, mout[2:0]};
   // instantiate hex decoder
   hex_to_sseg sseg_unit
      (.hex(oct), .dp(1'b0), .sseg(led0));

   // sign displayed on 2nd 7-seg LED
   // middle LED bar on for negative number
	assign led1 = mout[3] ? 8'b01000000 : 8'b00000000;
   // blank two other LEDs
   assign led2 = 8'b00000000;
   assign led3 = 8'b00000000;

   // instantiate 7-seg LED display time-multiplexing module
   disp_mux disp_unit
      (.clk(clk), .reset(1'b0), .in0(led0), .in1(led1),
       .in2(led2), .in3(led3), .an(an), .sseg(sseg));

endmodule