// Listing 3.3
module and_cont_assign
  (
  input wire a, b, c,
  output wire y
  );

  assign y = a;
  assign y = y & b;
  assign y = y & c;

endmodule