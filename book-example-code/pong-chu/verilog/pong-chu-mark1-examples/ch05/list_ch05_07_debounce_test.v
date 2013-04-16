// Listing 5.7
/************************************************************
* Mark1 Notes
* - inverting logic level of btn's.  MJ
* - invert logic level of reset. MJ
* - invert dp_in constant
*************************************************************/
module debounce_test
   (
    input wire clk, reset,
    input wire [1:0] btn,
    output wire [3:0] an,
    output wire [7:0] sseg
   );

   // signal declaration
   reg [7:0]  b_reg, d_reg;
   wire [7:0] b_next, d_next;
   reg  btn_reg, db_reg;
   wire db_level, db_tick, btn_tick, clr;
	wire nreset;
	wire [1:0] nbtn;		//invert signas, based on spartan 3 starter design
	
	
	assign nreset = ~reset;	//invert the reset signal
	assign nbtn = ~btn;		//invert the btn signals	

   // instantiate 7-seg LED display time-multiplexing module
   disp_hex_mux disp_unit
      (.clk(clk), .reset(nreset),
       .hex3(b_reg[7:4]), .hex2(b_reg[3:0]),
       .hex1(d_reg[7:4]), .hex0(d_reg[3:0]),
       .dp_in(4'b0100), .an(an), .sseg(sseg));

   // instantiate debouncing circuit
   db_fsm db_unit
      (.clk(clk), .reset(nreset), .sw(nbtn[1]), .db(db_level));

   // edge detection circuits
   always @(posedge clk)
      begin
         btn_reg <= nbtn[1];
         db_reg <= db_level;
      end
		
		
   assign btn_tick = ~btn_reg & nbtn[1];
   assign db_tick = ~db_reg & db_level;

   // two counters
   assign clr = nbtn[0];
   always @(posedge clk)
      begin
         b_reg <= b_next;
         d_reg <= d_next;
      end
   assign b_next = (clr)      ? 8'b0 :
                   (btn_tick) ? b_reg + 1 : b_reg;
   assign d_next = (clr)      ? 8'b0 :
                   (db_tick)  ? d_reg + 1 : d_reg;

endmodule
