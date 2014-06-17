//Listing 9.5
//-- notes to run on logi:
//-- * using minicom running on the rpi to act as the uart interface to the fpga
//--		--you must have minicom installed and make a connection with 8n1 baud:19200.
//-- 		see: http://www.hobbytronics.co.uk/raspberry-pi-serial-port to install and run minicom
//-- 		1) run: sudo apt-get install minicom
//--		2) run: minicom -b 19200 -o -D /dev/ttyAMA0
module kb_test
   (
    input wire clk, reset_n,
    input wire ps2d_1, ps2c_1,
    output wire tx
   );

   // signal declaration
   wire [7:0] key_code, ascii_code;
   wire kb_not_empty, kb_buf_empty;
	wire ps2d, ps2c, reset;
	
	
	assign reset = ~reset_n;
	assign ps2d = ps2d_1;
	assign ps2c = ps2c_1;
	
   // body
   // instantiate keyboard scan code circuit
   kb_code kb_code_unit
      (.clk(clk), .reset(reset), .ps2d(ps2d), .ps2c(ps2c),
       .rd_key_code(kb_not_empty), .key_code(key_code),
       .kb_buf_empty(kb_buf_empty));

   // instantiate UART
   uart uart_unit
      (.clk(clk), .reset(reset), .rd_uart(1'b0),
       .wr_uart(kb_not_empty), .rx(1'b1), .w_data(ascii_code),
       .tx_full(), .rx_empty(), .r_data(), .tx(tx));

   // instantiate key-to-ascii code conversion circuit
   key2ascii k2a_unit
      (.key_code(key_code), .ascii_code(ascii_code));

   assign kb_not_empty = ~kb_buf_empty;

endmodule