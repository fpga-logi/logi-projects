// Listing 3.20
//--******************************************************************
//-- Note to run on logi:
//-- * The led to sseg display is used on the 4x sseg display.  This emulates 
//-- 	8 x linear leds. 
//-- * The bit pattern upper 6 bits are static "110101" with the low 2 bits
//-- taken from the swith values.  
//-- - The pushbuttons are used to shift the bit pattern
//--*******************************************************************/
module shifter_test
   (
	 input wire clk,
    input wire [1:0] btn_n,
    input wire [1:0] sw_n,
	 output wire [3:0] an,
	 output wire [7:0] sseg
   );

	wire [1:0] btn, sw;
	wire [7:0] led;
	
	assign btn = ~btn_n;	//invert the btn signal active high.
	assign sw = ~sw_n;	
	
   // instantiate shifter
   barrel_shifter_stage shift_unit
     (.a( {6'b110101, sw} ), .amt( {1'b0,btn} ), .y(led));

	// instantiate led to ssegment display (emulate 8 linear leds.)
	led8_sseg led_sseg_unit
		(.clk(clk), .reset(1'b0), .led(led), .an_edu(an), .sseg_out(sseg));


endmodule