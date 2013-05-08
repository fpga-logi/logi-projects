// Listing 13.2
/****************************************************************
* mark1 mod notes:
* - inverted the reset signal.
*****************************************************************/
module vga_test
   (
    input wire clk, reset,
    input wire [2:0] sw,
    output wire hsync, vsync,
    output wire [2:0] rgb
   );

	
   //signal declaration
   reg [2:0] rgb_reg;
   wire video_on;
	wire nreset;
	
	assign nreset = ~reset;

   // instantiate vga sync circuit
   vga_sync vsync_unit
      (	.clk(clk), 
			.reset(nreset), 
			.hsync(hsync), 
			.vsync(vsync),
			.video_on(video_on), 
			.p_tick(), 
			.pixel_x(), 
			.pixel_y()
		);
		
   // rgb buffer
   always @(posedge clk, posedge nreset)
      if (nreset)
         rgb_reg <= 0;
      else
         rgb_reg <= sw;
   // output
   assign rgb = (video_on) ? rgb_reg : 3'b0;

endmodule