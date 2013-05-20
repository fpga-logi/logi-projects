// Listing 3.20
/****************************************************************
* Mark1 Notes:
* - inverting logic level of btn.  MJ
*****************************************************************/
module shifter_test
   (
    input wire [2:0] btn,
    input wire [7:0] sw,
    output wire [7:0] led
   );

   // instantiate shifter
   barrel_shifter_stage shift_unit
     (.a(sw), .amt(~btn), .y(led));

endmodule