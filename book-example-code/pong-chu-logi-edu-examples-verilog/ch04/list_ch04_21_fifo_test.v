// Listing 4.21
// notes to run on logi:
// * the read write functions are controlled by btn(0)=write and btn(1)=read
// * the sw(1:0) controls the write data that is written into the fifo when write btn is pushed.
// * When btn(1) is pushed the data is read from the fifo and dispalyed on bit(1:0) of the leds.
// * the 4xsseg dispaly is used to emulate 8x linear leds that will display the buffer
// status and read data.  
module fifo_test
   (
    input wire clk,
    input wire [1:0] btn_n,
    input wire [1:0] sw_n,
	 output wire [3:0] an,
	 output wire [7:0] sseg
   );

   // signal declaration
   wire [1:0] db_btn;
	wire [1:0] btn,sw;
	wire [7:0] led;
	
	assign btn = ~btn_n;
	assign sw = ~sw_n;

   // debounce circuit for btn[0]
   debounce btn_db_unit0
      (.clk(clk), .reset(1'b0), .sw(btn[0]),
       .db_level(), .db_tick(db_btn[0]));
   // debounce circuit for btn[1]
   debounce btn_db_unit1
      (.clk(clk), .reset(1'b0), .sw(btn[1]),
       .db_level(), .db_tick(db_btn[1]));
   // instantiate a 2^2-by-3 fifo
   fifo #(.B(3), .W(2)) fifo_unit
      (.clk(clk), .reset(1'b0),
      .rd(db_btn[0]), 
		.wr(db_btn[1]), 
		.w_data( {1'b0,sw} ),
      .r_data(led[2:0]), 
		.full(led[7]), 
		.empty(led[6])
		);
   // disable unused leds
   assign led[5:3] = 3'b000;
	
	
		// instantiate led to ssegment display (emulate 8 linear leds.)
	led8_sseg led_sseg_unit
		(.clk(clk), .reset(1'b0), .led(led), .an_edu(an), .sseg_out(sseg));

 endmodule

