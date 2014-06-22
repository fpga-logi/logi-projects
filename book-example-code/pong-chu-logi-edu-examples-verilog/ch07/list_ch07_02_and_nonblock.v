// Listing 7.2
module and_nonblock
  (
  input wire a, b, c,
  output reg y
  );

  always @*
  begin             // y$_{entry}$ =  y
     y <= a;        // y$_{exit}$ = a
     y <= y & b;    // y$_{exit}$ = y$_{entry}$ \& b
     y <= y & c;    // y$_{exit}$ = y$_{entry}$ \& c
  end               // y = y$_{exit}$

endmodule