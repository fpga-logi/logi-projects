//Listing 10.1
module ps2_tx
   (
    input wire clk, reset,
    input wire wr_ps2,
    input wire [7:0] din,
    inout wire ps2d, ps2c,
    output reg tx_idle, tx_done_tick
   );

   // symbolic state declaration
   localparam [2:0]
      idle  = 3'b000,
      rts   = 3'b001,
      start = 3'b010,
      data  = 3'b011,
      stop  = 3'b100;

   // signal declaration
   reg [2:0] state_reg, state_next;
   reg [7:0] filter_reg;
   wire [7:0] filter_next;
   reg f_ps2c_reg;
   wire f_ps2c_next;
   reg [3:0] n_reg, n_next;
   reg [8:0] b_reg, b_next;
   reg [12:0] c_reg, c_next;
   wire par, fall_edge;
   reg ps2c_out, ps2d_out;
   reg tri_c, tri_d;

   // body
   //=================================================
   // filter and falling-edge tick generation for ps2c
   //=================================================
   always @(posedge clk, posedge reset)
   if (reset)
      begin
         filter_reg <= 0;
         f_ps2c_reg <= 0;
      end
   else
      begin
         filter_reg <= filter_next;
         f_ps2c_reg <= f_ps2c_next;
      end

   assign filter_next = {ps2c, filter_reg[7:1]};
   assign f_ps2c_next = (filter_reg==8'b11111111) ? 1'b1 :
                        (filter_reg==8'b00000000) ? 1'b0 :
                         f_ps2c_reg;
   assign fall_edge = f_ps2c_reg & ~f_ps2c_next;

   //=================================================
   // FSMD
   //=================================================
   // FSMD state & data registers
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            state_reg <= idle;
            c_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
         end
      else
         begin
            state_reg <= state_next;
            c_reg <= c_next;
            n_reg <= n_next;
            b_reg <= b_next;
         end

   // odd parity bit
   assign par = ~(^din);

   // FSMD next-state logic
   always @*
   begin
      state_next = state_reg;
      c_next = c_reg;
      n_next = n_reg;
      b_next = b_reg;
      tx_done_tick = 1'b0;
      ps2c_out = 1'b1;
      ps2d_out = 1'b1;
      tri_c = 1'b0;
      tri_d = 1'b0;
      tx_idle = 1'b0;
      case (state_reg)
         idle:
            begin
               tx_idle = 1'b1;
               if (wr_ps2)
                  begin
                     b_next = {par, din};
                     c_next = 13'h1fff; // 2^13-1
                     state_next = rts;
                  end
            end
         rts:   // request to send
            begin
               ps2c_out = 1'b0;
               tri_c = 1'b1;
               c_next = c_reg - 1;
               if (c_reg==0)
                  state_next = start;
            end
         start:  // assert start bit
            begin
               ps2d_out = 1'b0;
               tri_d = 1'b1;
               if (fall_edge)
                  begin
                     n_next = 4'h8;
                     state_next = data;
                  end
            end
         data:   //  8 data + 1 parity
            begin
               ps2d_out = b_reg[0];
               tri_d = 1'b1;
               if (fall_edge)
                  begin
                     b_next = {1'b0, b_reg[8:1]};
                     if (n_reg == 0)
                        state_next = stop;
                     else
                        n_next = n_reg - 1;
                  end
            end
         stop:   // assume floating high for ps2d
            if (fall_edge)
               begin
                  state_next = idle;
                  tx_done_tick = 1'b1;
               end
      endcase
   end

   // tri-state buffers
   assign ps2c = (tri_c) ? ps2c_out : 1'bz;
   assign ps2d = (tri_d) ? ps2d_out : 1'bz;

endmodule