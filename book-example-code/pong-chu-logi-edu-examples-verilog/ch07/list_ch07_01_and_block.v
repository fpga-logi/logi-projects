// Listing 7.1
module and_block
  (
  input wire a, b, c,
  output reg y
  );

  always @*
  begin
     y = a;
     y = y & b;
     y = y & c;
  end

endmodule