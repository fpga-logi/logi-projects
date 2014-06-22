// Listing 7.3
module eq1_block
  (
  input wire i0, i1,
  output reg eq
  );

  reg p0, p1;

  always @(i0,i1) // only i0 and i1 in sensitivity list
  // the order of statements is important
  begin
     p0 = ~i0 & ~i1;
     p1 = i0 & i1;
     eq = p0 | p1;
  end

endmodule
