// Listing 5.6
module db_fsm
   (
    input wire clk, reset,
    input wire sw,
    output reg db
   );

   // symbolic state declaration
   localparam  [2:0]
               zero    = 3'b000,
               wait1_1 = 3'b001,
               wait1_2 = 3'b010,
               wait1_3 = 3'b011,
               one     = 3'b100,
               wait0_1 = 3'b101,
               wait0_2 = 3'b110,
               wait0_3 = 3'b111;

   // number of counter bits (2^N * 20ns = 10ms tick)
   localparam N =19;

   // signal declaration
   reg [N-1:0] q_reg;
   wire [N-1:0] q_next;
   wire m_tick;
   reg [2:0] state_reg, state_next;

   // body

   //=============================================
   // counter to generate 10 ms tick
   //=============================================
   always @(posedge clk)
      q_reg <= q_next;
   // next-state logic
   assign q_next = q_reg + 1;
   // output tick
   assign m_tick = (q_reg==0) ? 1'b1 : 1'b0;

   //=============================================
   // debouncing FSM
   //=============================================
   // state register
    always @(posedge clk, posedge reset)
       if (reset)
          state_reg <= zero;
       else
          state_reg <= state_next;

   // next-state logic and output logic
   always @*
   begin
      state_next = state_reg;  // default state: the same
      db = 1'b0;               // default output: 0
      case (state_reg)
         zero:
            if (sw)
               state_next = wait1_1;
         wait1_1:
            if (~sw)
               state_next = zero;
            else
               if (m_tick)
                  state_next = wait1_2;
         wait1_2:
            if (~sw)
               state_next = zero;
            else
               if (m_tick)
                  state_next = wait1_3;
         wait1_3:
            if (~sw)
               state_next = zero;
            else
               if (m_tick)
                  state_next = one;
         one:
            begin
              db = 1'b1;
              if (~sw)
                 state_next = wait0_1;
            end
         wait0_1:
            begin
               db = 1'b1;
               if (sw)
                  state_next = one;
               else
                 if (m_tick)
                    state_next = wait0_2;
            end
         wait0_2:
            begin
               db = 1'b1;
               if (sw)
                  state_next = one;
               else
                 if (m_tick)
                    state_next = wait0_3;
            end
         wait0_3:
            begin
               db = 1'b1;
               if (sw)
                  state_next = one;
               else
                 if (m_tick)
                    state_next = zero;
            end
         default: state_next = zero;
      endcase
   end

endmodule