// Listing 1.2
module eq1_implicit
   (
    input i0, i1,  // no data type declaration
    output eq
   );

// no internal signal declaration

// product terms must be placed in front
assign p0 = ~i0 & ~i1;   //implicit declaration
assign p1 = i0 & i1;     //implicit declaration
// sum of two product terms
assign eq = p0 | p1;

endmodule