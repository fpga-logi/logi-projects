// Listing 7.11
module div_combined
   #(
     parameter W = 8,
               CBIT = 4   // CBIT=log2(W)+1
    )
   (
    input wire clk, reset,
    input wire start,
    input wire [W-1:0] dvsr, dvnd,
    output wire ready, done_tick,
    output wire [W-1:0] quo, rmd
   );

   // symbolic state declaration
   localparam [1:0]
      idle = 2'b00,
      op   = 2'b01,
      last = 2'b10,
      done = 2'b11;

   // signal declaration
   reg [1:0] state_reg;
   reg [W-1:0] rh_reg, rl_reg,  rh_tmp, d_reg;
   reg [CBIT-1:0] n_reg, n_next;
   reg q_bit;

   // fsmd registers and next-state logic
   always @(posedge clk, posedge reset)
   begin
      if (reset)
         begin
            state_reg <= idle;
            rh_reg <= 0;
            rl_reg <= 0;
            d_reg <= 0;
            n_reg <= 0;
         end
      else
         begin
            //==============================================
            // data path functional units
            // to get intermediate results
            //==============================================
            // compare and subtract circuit
            if (rh_reg >= d_reg)
               begin
                  rh_tmp = rh_reg - d_reg;
                  q_bit = 1'b1;
               end
            else
               begin
                  rh_tmp = rh_reg;
                  q_bit = 1'b0;
               end
            // index decrement circuit
            n_next = n_reg - 1;

            //==============================================
            // state and data registers and next-state logic
            //==============================================
            case (state_reg)
               idle:
                  begin
                     if (start)
                        begin
                           rh_reg <= 0;
                           rl_reg <= dvnd;   // dividend
                           d_reg <= dvsr;   // divisor
                           n_reg <= CBIT;   // index
                           state_reg <= op;
                        end
                  end
               op:
                  begin
                     // shift rh and rl left
                     rl_reg <= {rl_reg[W-2:0], q_bit};
                     rh_reg <= {rh_tmp[W-2:0], rl_reg[W-1]};
                     // decrease index
                     n_reg <= n_next;
                     if (n_next==1)
                        state_reg <= last;
                  end
               last: // last iteration
                  begin
                     rl_reg <= {rl_reg[W-2:0], q_bit};
                     rh_reg <= rh_tmp;
                     state_reg <= done;
                  end
               done:
                  state_reg <= idle;
               default: state_reg <= idle;
            endcase
         end
      end

   // output
   assign quo = rl_reg;
   assign rmd = rh_reg;
   // unregistered output
   assign ready = (state_reg==idle);
   assign done_tick = (state_reg==done);

endmodule
