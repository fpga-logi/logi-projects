// Listing 13.4
/***************************************************************
* Mark-1 Mod:
* - inverting reset signal
****************************************************************/
module pong_top_st
   (
    input wire clk, reset,
    output wire hsync, vsync,
    output wire [2:0] rgb
   );

   // signal declaration
   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick;
   reg [2:0] rgb_reg;
   wire [2:0] rgb_next;
	wire nreset;
	
	assign nreset = ~reset;

   // body
   // instantiate vga sync circuit
   vga_sync vsync_unit
      (	.clk(clk), 
			.reset(nreset), 
			.hsync(hsync), 
			.vsync(vsync),
			.video_on(video_on), 
			.p_tick(pixel_tick),
			.pixel_x(pixel_x), 
			.pixel_y(pixel_y)
		);
   // instantiate graphic generator
   pong_graph_st pong_grf_unit
      (	.video_on(video_on), 
			.pix_x(pixel_x), 
			.pix_y(pixel_y),
			.graph_rgb(rgb_next)
		);
   // rgb buffer
   always @(posedge clk)
      if (pixel_tick)
         rgb_reg <= rgb_next;
   // output
   assign rgb = rgb_reg;

endmodule
