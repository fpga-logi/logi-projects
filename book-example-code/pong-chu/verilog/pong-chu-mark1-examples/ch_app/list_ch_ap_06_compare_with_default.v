// Listing A.6
module compare_with_default
   (
    input wire a, b,
    output reg gt, eq
   );

   // - use @* to include all inputs in sensitivity list
   // - assign each output with a default value
   always @*
   begin
      gt = 1'b0;  // default value for gt
      eq = 1'b0;  // default value for eq
      if (a > b)
         gt = 1'b1;
      else if (a == b)
         eq = 1'b1;
   end

endmodule
