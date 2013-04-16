// Listing 6.8
module low_freq_counter
   (
    input wire clk, reset,
    input wire start, si,
    output wire [3:0] bcd3, bcd2, bcd1, bcd0
   );

   // symbolic state declaration
   localparam  [1:0]
               idle  = 2'b00,
               count = 2'b01,
               frq   = 2'b10,
               b2b   = 2'b11;

   // signal declaration
   reg [1:0] state_reg, state_next;
   wire [9:0] prd;
   wire [19:0] dvsr, dvnd, quo;
   reg prd_start, div_start, b2b_start;
   wire prd_done_tick, div_done_tick, b2b_done_tick;

   //===============================================
   // component instantiation
   //===============================================
   // instantiate period counter
   period_counter prd_count_unit
      (.clk(clk), .reset(reset), .start(prd_start), .si(si),
       .ready(), .done_tick(prd_done_tick), .prd(prd));
   // instantiate division circuit
   div #(.W(20), .CBIT(5)) div_unit
      (.clk(clk), .reset(reset), .start(div_start),
       .dvsr(dvsr), .dvnd(dvnd), .quo(quo), .rmd(),
       .ready(), .done_tick(div_done_tick));
   // instantiate binary-to-BCD convertor
   bin2bcd b2b_unit
      (.clk(clk), .reset(reset), .start(b2b_start),
       .bin(quo[12:0]), .ready(), .done_tick(b2b_done_tick),
       .bcd3(bcd3), .bcd2(bcd2), .bcd1(bcd1), .bcd0(bcd0));
   // signal width extension
   assign dvnd = 20'd1000000;
   assign dvsr = {10'b0, prd};

   //===============================================
   // master FSM
   //===============================================
   always @(posedge clk, posedge reset)
     if (reset)
        state_reg <= idle;
     else
        state_reg <= state_next;

   always @*
   begin
      state_next = state_reg;
      prd_start = 1'b0;
      div_start = 1'b0;
      b2b_start = 1'b0;
      case (state_reg)
         idle:
            if (start)
               begin
                  prd_start = 1'b1;
                  state_next = count;
               end
         count:
            if (prd_done_tick)
               begin
                  div_start = 1'b1;
                  state_next = frq;
               end
         frq:
            if (div_done_tick)
               begin
                  b2b_start = 1'b1;
                  state_next = b2b;
               end
         b2b:
            if (b2b_done_tick)
               state_next = idle;
       endcase
   end

endmodule
