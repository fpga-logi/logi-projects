// Listing 3.22
//--******************************************************************
//-- Notes to run on logi:
//-- user can experiment by hard coding the folowing values are 
//-- using the push buttons or switches to change the parameters
//--*******************************************************************/
module fp_adder_test
   (
    input wire clk,
    input wire [1:0] btn_n,
    input wire [1:0] sw_n,
    output wire [3:0] an,
    output wire [7:0] sseg
   );

   // signal declarations
   wire sign1, sign2, sign_out;
   wire [3:0] exp1, exp2, exp_out;
   wire [7:0] frac1, frac2, frac_out;
   wire [7:0] led3, led2, led1, led0;
	wire [1:0] btn, sw;


	assign btn = ~btn_n;
	assign sw = ~sw_n;

   // body
   // set up the fp adder input signals
   assign sign1 = 1'b0;
   assign exp1 = 4'b0010;
   assign frac1 = {1'b1, 1'b0, sw[0], 5'b00010};
   assign sign2 = sw[1];
   assign exp2 = {2'b00, btn};
   assign frac2 = {1'b1, 7'b0000001};

   // instantiate fp adder
   fp_adder fp_unit
      (.sign1(sign1), 
		.sign2(sign2), 
		.exp1(exp1), 
		.exp2(exp2),
      .frac1(frac1), 
		.frac2(frac2), 
		.sign_out(sign_out),
      .exp_out(exp_out), 
		.frac_out(frac_out));

   // instantiate three instances of hex decoders
   // exponent
   hex_to_sseg sseg_unit_0
      (.hex(exp_out), .dp(1'b0), .sseg(led0));
   // 4 LSBs of fraction
   hex_to_sseg sseg_unit_1
      (.hex(frac_out[3:0]), .dp(1'b1), .sseg(led1));
   // 4 MSBs of fraction
   hex_to_sseg sseg_unit_2
      (.hex(frac_out[7:4]), .dp(1'b0), .sseg(led2));
  //sign
   //assign led3 = (sign_out) ? 8'b11111110 : 8'b11111111;
	assign led3 = (sign_out) ? 8'b01000000 : 8'b00000000;

   // instantiate 7-seg LED display time-multiplexing module
   disp_mux disp_unit
      (.clk(clk), .reset(1'b0), .in0(led0), .in1(led1),
       .in2(led2), .in3(led3), .an(an), .sseg(sseg));

endmodule