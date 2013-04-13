// Listing 1.5
module eq1_primitive
  (
   input wire i0, i1,
   output wire eq
  );

  // internal signal declaration
  wire i0_n, i1_n, p0, p1;

  //primitive gate instantiations
  not unit1 (i0_n, i0);       // i0_n = ~i0;
  not unit2 (i1_n, i1);       // i1_n = ~i1;
  and unit3 (p0, i0_n, i1_n); // p0 = i0_n & i1_n;
  and unit4 (p1, i0, i1);     // p1 = i0 & i1;
  or unit5 (eq, p0, p1);      // eq = p0 | p1;

endmodule