// Listing 2.1
module eq1
   // I/O ports
   (
    input wire i0, i1,
    output wire eq
   );

   // signal declaration
   wire p0, p1;

   // body
   // sum of two product terms
   assign eq = p0 | p1;
   // product terms
   assign p0 = ~i0 & ~i1;
   assign p1 = i0 & i1;

endmodule