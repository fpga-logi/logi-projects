//Listing 8.5
//-- * notes to run on logi
//-- * using led-sseg display to show the led values
//-- * using onboard leds to show the buffer full/empty
//-- * using minicom running on the rpi to act as the uart interface to the fpga
//--		--you must have minicom installed and make a connection with 8n1 baud:19200.
//-- 		see: http://www.hobbytronics.co.uk/raspberry-pi-serial-port to install and run minicom
//-- 		1) run: sudo apt-get install minicom
//--		2) run: minicom -b 19200 -o -D /dev/ttyAMA0

module uart_test
   (
    input wire clk,
    input wire rx,
    input wire [1:0] btn_n,
    output wire tx,
	 output [1:0] led,
    output wire [3:0] an,
    output wire [7:0] sseg
   );
	

   // signal declaration
   wire tx_full, rx_empty, btn_tick, reset;
   wire [7:0] rec_data, rec_data1 , led_sseg;
	wire [1:0] btn;
	
	assign btn = ~btn_n;
	assign reset = 1'b0;

   // body
   // instantiate uart
   uart uart_unit
      (.clk(clk), .reset(reset), .rd_uart(btn_tick),
       .wr_uart(btn_tick), .rx(rx), .w_data(rec_data1),
       .tx_full(tx_full), .rx_empty(rx_empty),
       .r_data(rec_data), .tx(tx));
   // instantiate debounce circuit
   debounce btn_db_unit
      (.clk(clk), .reset(reset), .sw(btn[0]),
       .db_level(), .db_tick(btn_tick));
   // incremented data loops back
   assign rec_data1 = rec_data + 1;
   // LED display
   assign led_sseg = rec_data;
   //assign an = 4'b1110;
   //assign sseg = {1'b1, ~tx_full, 2'b11, ~rx_empty, 3'b111};
	
	assign led[0] = tx_full;
	assign led[1] = rx_empty;
	
	 // instantiate led to ssegment display (emulate 8 linear leds.)
	led8_sseg led_sseg_unit
		(.clk(clk), .reset(1'b0), .led(led_sseg), .an_edu(an), .sseg_out(sseg));


endmodule