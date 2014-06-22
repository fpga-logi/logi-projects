// Listing 7.16
module eq2_function
  (
  input  wire [1:0] a, b,
  output reg aeqb
  );

  reg e0, e1;

  always @*
  begin
     #2 e0 = equ_fnc(a[0], b[0]);
     #2 e1 = equ_fnc(a[1], b[1]);
     aeqb = e0 & e1;
  end

// function definition
function equ_fnc(input i0, i1);
   begin
      equ_fnc = (~i0 & ~i1) | (i0 & i1);
   end
endfunction

endmodule