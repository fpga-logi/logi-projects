// Listing A.5
module compare_no_defult
   (
    input wire a, b,
    output reg gt, eq
   );

   // - use @* to include all inputs in sensitivity list
   // - else branch cannot be omitted
   // - all outputs must be assigned in all branches
   always @*
      if (a > b)
         begin
            gt = 1'b1;
            eq = 1'b0;
         end
      else if (a == b)
         begin
            gt = 1'b0;
            eq = 1'b1;
         end
      else   // else branch cannot be omitted
         begin
            gt = 1'b0;
            eq = 1'b0;
         end

endmodule
