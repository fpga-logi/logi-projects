// Listing 3.13
module adder_carry_95 (a, b, sum, cout);
   parameter N = 4;     // parameter declared before the port
   parameter N1 = N-1;  // no localparam in Verilog-1995
   input wire [N1:0] a, b;
   output wire [N1:0] sum;
   output wire cout;

   // signal declaration
   wire [N:0] sum_ext;

   //body
   assign sum_ext = {1'b0, a} + {1'b0, b};
   assign sum = sum_ext[N1:0];
   assign cout= sum_ext[N];

endmodule