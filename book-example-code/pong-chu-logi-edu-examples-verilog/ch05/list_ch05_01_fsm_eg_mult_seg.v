// Listing 5.1
module fsm_eg_mult_seg
   (
    input wire  clk, reset,
    input wire  a, b,
    output wire y0, y1
   );

   // symbolic state declaration
   localparam [1:0] s0 = 2'b00,
                    s1 = 2'b01,
                    s2 = 2'b10;

   // signal declaration
   reg [1:0] state_reg, state_next;

   // state register
    always @(posedge clk, posedge reset)
       if (reset)
          state_reg <= s0;
       else
          state_reg <= state_next;

   // next-state logic
   always @*
      case (state_reg)
         s0: if (a)
               if (b)
                  state_next = s2;
               else
                  state_next = s1;
             else
                state_next = s0;
         s1: if (a)
               state_next = s0;
             else
               state_next = s1;
         s2: state_next = s0;
         default: state_next = s0;
      endcase

   // Moore output logic
   assign y1 = (state_reg==s0) || (state_reg==s1);

   // Mealy output logic
   assign y0 = (state_reg==s0) & a & b;

endmodule