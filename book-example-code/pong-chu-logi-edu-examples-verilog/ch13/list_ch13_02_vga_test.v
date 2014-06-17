// Listing 13.2
//-- notes to run on logi:
// * uses [sw[0:1], btn[1]) to control the rgb colors.
//-- * - reset was disbled, converte 3 bit to 9 bit color on edu board.
module vga_test
   (
    input wire clk,
    input wire [1:0] sw_n, btn_n,
    output wire hsync, vsync,
    output wire [2:0] red, green, blue
   );

   //signal declaration
   reg [2:0] rgb_reg;
   wire video_on;
	wire [1:0] btn, sw;
	wire reset;
	
	assign btn = ~btn_n;
	assign sw = ~sw_n;
	assign reset = btn[0];

   // instantiate vga sync circuit
   vga_sync vsync_unit
      (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),
       .video_on(video_on), .p_tick(), .pixel_x(), .pixel_y());
   // rgb buffer
   always @(posedge clk, posedge reset)
      if (reset)
         rgb_reg <= 0;
      else
         rgb_reg <= {sw, btn[1]};
   // output
   //assign rgb = (video_on) ? rgb_reg : 3'b0;
	
	assign red = (video_on && rgb_reg[0] == 1'b1) ? 3'b111 : 3'b000;
	assign green = (video_on && rgb_reg[1] == 1'b1) ? 3'b111 : 3'b000;
	assign blue = (video_on && rgb_reg[2] == 1'b1) ? 3'b111 : 3'b000;



endmodule