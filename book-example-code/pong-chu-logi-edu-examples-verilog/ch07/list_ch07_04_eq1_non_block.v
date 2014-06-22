// Listing 7.4
module eq1_non_block
  (
  input wire i0, i1,
  output reg eq
  );

  reg p0, p1;

  always @(i0,i1,p0,p1) // p0, p1 also in sensitivity list
  // the order of statements is not important
  begin               // p0$_{entry}$ = p0; p1$_{entry}$ =  p1;
     p0 <= ~i0 & ~i1; // p0$_{exit}$ = ~i0 \& ~i1;
     p1 <= i0 & i1;   // p1$_{exit}$ = i0 \& i1
     eq <= p0 | p1;   // eq$_{exit}$ = p0$_{entry}$ | p1$_{entry}$
  end                 // eq = eq$_{exit}$; p0 = p0$_{exit}$; p1 = p1$_{exit}$;

endmodule
