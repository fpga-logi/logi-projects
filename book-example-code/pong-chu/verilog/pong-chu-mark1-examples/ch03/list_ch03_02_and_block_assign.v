// Listing 3.2
module and_block_assign
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