//Listing 7.19
`timescale 1 ns/10 ps

module bin_counter_tb3();

   //  declaration
   localparam  T=20; // clock period
   wire clk, reset;
   wire syn_clr, load, en, up;
   wire [2:0] d;
   wire max_tick, min_tick;
   wire [2:0] q;

   // uut instantiation
   univ_bin_counter #(.N(3)) uut
     (.clk(clk), .reset(reset), .syn_clr(syn_clr),
      .load(load), .en(en), .up(up), .d(d),
      .max_tick(max_tick), .min_tick(min_tick), .q(q));

   // test vector generator
   bin_gen #(.N(3),.T(20)) gen_unit
     (.clk(clk), .reset(reset), .syn_clr(syn_clr),
      .load(load), .en(en), .up(up), .d(d));

   // bin_monitor instantiation
   bin_monitor #(.N(3)) mon_unit
     (.clk(clk), .reset(reset), .syn_clr(syn_clr),
      .load(load), .en(en), .up(up), .d(d),
      .max_tick(max_tick), .min_tick(min_tick), .q(q));

endmodule