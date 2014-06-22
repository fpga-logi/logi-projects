// Listing 7.6
module ab_ff_all
   (
    input wire clk,
    input wire a, b,
    output reg q0, q1, q2, q3, q4, q5
   );

   reg ab0, ab1, ab2, ab3, ab4, ab5;

   //  attempt 0
   always @(posedge clk)
   begin
      ab0 = a & b;
      q0 <= ab0;
   end

   // attempt 1
   always @(posedge clk)
   begin            // ab1$_{entry}$ = ab1; q1$_{entry}$ = q1;
      ab1 <= a & b; // ab1$_{exit}$ = a \& b
      q1 <= ab1;    // q1$_{exit}$ = ab1$_{entry}$
   end              // ab1 = ab1$_{exit}$; q1 = q1$_{exit}$

   // attempt 2
   always @(posedge clk)
   begin
      ab2 = a & b;
      q2 = ab2;

   end

   // attempt 3 (switch the order of attempt 0)
   always @(posedge clk)
   begin
      q3 <= ab3;
      ab3 = a & b;
   end

   // attempt 4 (switch the order of attempt 1)
   always @(posedge clk)
   begin            // ab4$_{entry}$ = ab4; q4$_{entry}$ = q4;
      q4 <= ab4;    // q4$_{exit}$ = ab4$_{entry}$
      ab4 <= a & b; // ab4$_{exit}$ = a \& b
   end              // ab4 = ab4$_{exit}$; q4 = q4$_{exit}$

   // attempt 5 (switch the order of attempt 2)
   always @(posedge clk)
   begin
      q5 = ab5;
      ab5 = a & b;
   end

endmodule
