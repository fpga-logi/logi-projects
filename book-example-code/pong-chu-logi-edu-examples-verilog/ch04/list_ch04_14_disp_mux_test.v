// Listing 4.14
//--Notes to run on logi:  
//-- * Using a 2 registers rather than 4.
//-- * the upper 6 bits of the register are  are a static value of "000000" 
//--  	the lower 2 bits are taken from the sw(1:0) values.  
//-- * btn(0) latches regsiter 1, btn(1) latches regsiter 2.
module disp_mux_test
   (
    input wire clk,
    input wire [1:0] btn_n,
    input wire [1:0] sw_n,
    output wire [3:0] an,
    output wire [7:0] sseg
   );

   // signal declaration
   reg [7:0] d3_reg, d2_reg, d1_reg, d0_reg;
	wire [1:0] sw, btn;
	
	assign sw = ~sw_n;
	assign btn = ~btn_n;

   // instantiate 7-seg LED display time-multiplexing module
   disp_mux disp_unit
      (	.clk(clk), 
			.reset(1'b0), 
			.in0(d0_reg), 
			.in1(d0_reg),
			.in2(d1_reg), 
			.in3(d1_reg), 
			.an(an), 
			.sseg(sseg)
		);

   // registers for 2 led patterns
   always @(posedge clk)
   begin
      if (btn == 2'b10)
         d1_reg <= {6'b000000, sw};
		if (btn == 2'b01)
         d0_reg <= {6'b000000, sw};
    end

endmodule