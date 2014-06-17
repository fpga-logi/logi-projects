// Listing 13.6
module pong_top_an
   (
    input wire clk,
    input wire [1:0] btn_n,
    output wire hsync, vsync,
    output wire [2:0] red, green, blue
   );

   // signal declaration
   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick;
   reg [2:0] rgb_reg;
   wire [2:0] rgb_next;
	wire reset;
	wire [1:0] btn;
	
	assign reset = 1'b0;
	assign btn = ~btn_n;

   // body
   // instantiate vga sync circuit
   vga_sync vsync_unit
      (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),
       .video_on(video_on), .p_tick(pixel_tick),
       .pixel_x(pixel_x), .pixel_y(pixel_y));

   // instantiate graphic generator
   pong_graph_animate pong_graph_an_unit
      (.clk(clk), .reset(reset), .btn(btn),
       .video_on(video_on), .pix_x(pixel_x),
       .pix_y(pixel_y), .graph_rgb(rgb_next));

   // rgb buffer
   always @(posedge clk)
      if (pixel_tick)
         rgb_reg <= rgb_next;
   // output
   assign red = (video_on && rgb_reg[0] == 1'b1) ? 3'b111 : 3'b000;
	assign green = (video_on && rgb_reg[1] == 1'b1) ? 3'b111 : 3'b000;
	assign blue = (video_on && rgb_reg[2] == 1'b1) ? 3'b111 : 3'b000;

endmodule
