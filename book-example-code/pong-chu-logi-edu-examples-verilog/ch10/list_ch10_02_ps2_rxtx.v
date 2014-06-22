//Listing 10.2
module ps2_rxtx
   (
    input wire clk, reset,
    input wire wr_ps2,
    inout wire ps2d, ps2c,
    input wire [7:0] din,
    output wire rx_done_tick, tx_done_tick,
    output wire [7:0] dout
   );

   // signal declaration
   wire tx_idle;

   // body
   // instantiate ps2 receiver
   ps2_rx ps2_rx_unit
      (.clk(clk), .reset(reset), .rx_en(tx_idle),
       .ps2d(ps2d), .ps2c(ps2c),
       .rx_done_tick(rx_done_tick), .dout(dout));
   // instantiate ps2 transmitter
   ps2_tx ps2_tx_unit
      (.clk(clk), .reset(reset), .wr_ps2(wr_ps2),
       .din(din), .ps2d(ps2d), .ps2c(ps2c),
       .tx_idle(tx_idle), .tx_done_tick(tx_done_tick));

endmodule
