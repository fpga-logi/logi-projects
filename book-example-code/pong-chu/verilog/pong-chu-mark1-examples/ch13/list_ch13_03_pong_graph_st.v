// Listing 13.3
module pong_graph_st
   (
    input wire video_on,
    input wire [9:0] pix_x, pix_y,
    output reg [2:0] graph_rgb
   );

   // constant and signal declaration
   // x, y coordinates (0,0) to (639,479)
   localparam MAX_X = 640;
   localparam MAX_Y = 480;
   //--------------------------------------------
   // vertical stripe as a wall
   //--------------------------------------------
   // wall left, right boundary
   localparam WALL_X_L = 32;
   localparam WALL_X_R = 35;
   //--------------------------------------------
   // right vertical bar
   //--------------------------------------------
   // bar left, right boundary
   localparam BAR_X_L = 600;
   localparam BAR_X_R = 603;
   // bar top, bottom boundary
   localparam BAR_Y_SIZE = 72;
   localparam BAR_Y_T = MAX_Y/2-BAR_Y_SIZE/2; //204
   localparam BAR_Y_B = BAR_Y_T+BAR_Y_SIZE-1;
   //--------------------------------------------
   // square ball
   //--------------------------------------------
   localparam BALL_SIZE = 8;
   // ball left, right boundary
   localparam BALL_X_L = 580;
   localparam BALL_X_R = BALL_X_L+BALL_SIZE-1;
   // ball top, bottom boundary
   localparam BALL_Y_T = 238;
   localparam BALL_Y_B = BALL_Y_T+BALL_SIZE-1;
   //--------------------------------------------
   // object output signals
   //--------------------------------------------
   wire wall_on, bar_on, sq_ball_on;
   wire [2:0] wall_rgb, bar_rgb, ball_rgb;

   // body
   //--------------------------------------------
   // (wall) left vertical strip
   //--------------------------------------------
   // pixel within wall
   assign wall_on = (WALL_X_L<=pix_x) && (pix_x<=WALL_X_R);
   // wall rgb output
   assign wall_rgb = 3'b001; // blue
   //--------------------------------------------
   // right vertical bar
   //--------------------------------------------
   // pixel within bar
   assign bar_on = (BAR_X_L<=pix_x) && (pix_x<=BAR_X_R) &&
                   (BAR_Y_T<=pix_y) && (pix_y<=BAR_Y_B);
   // bar rgb output
   assign bar_rgb = 3'b010; // green
   //--------------------------------------------
   // square ball
   //--------------------------------------------
   // pixel within squared ball
   assign sq_ball_on =
             (BALL_X_L<=pix_x) && (pix_x<=BALL_X_R) &&
             (BALL_Y_T<=pix_y) && (pix_y<=BALL_Y_B);
   assign ball_rgb = 3'b100;   // red
   //--------------------------------------------
   // rgb multiplexing circuit
   //--------------------------------------------
   always @*
      if (~video_on)
         graph_rgb = 3'b000; // blank
      else
         if (wall_on)
            graph_rgb = wall_rgb;
         else if (bar_on)
            graph_rgb = bar_rgb;
         else if (sq_ball_on)
            graph_rgb = ball_rgb;
         else
            graph_rgb = 3'b110; // yellow background

endmodule