// Listing 2.2
module eq2
   (
    input  wire[1:0] a, b,
    output wire aeqb
   );

   // internal signal declaration
   wire e0, e1;

   // body
   // instantiate two 1-bit comparators
   eq1 eq_bit0_unit (.i0(a[0]), .i1(b[0]), .eq(e0));
   eq1 eq_bit1_unit (.eq(e1), .i0(a[1]), .i1(b[1]));

   // a and b are equal if individual bits are equal
   assign aeqb = e0 & e1;

endmodule