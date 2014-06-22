//Listing 10.3
//-- notes to run on logi:
//-- * data from sw will have 6 bits static and low 2 bits from the sw.
//-- * using minicom running on the rpi to act as the uart interface to the fpga
//--		--you must have minicom installed and make a connection with 8n1 baud:19200.
//-- 		see: http://www.hobbytronics.co.uk/raspberry-pi-serial-port to install and run minicom
//-- 		1) run: sudo apt-get install minicom
//--		2) run: minicom -b 19200 -o -D /dev/ttyAMA0
module ps2_monitor
   (
    input wire clk,
    input wire [1:0] sw_n,
    input wire [1:0] btn_n,
    inout wire ps2d_1, ps2c_1,
    output wire tx
   );

   // constant declaration
   localparam SP=8'h20; // space in ASCII

  // symbolic state declaration
   localparam [1:0]
      idle  = 2'b00,
      send1 = 2'b01,
      send0 = 2'b10,
      sendb = 2'b11;
		
	//--A = 0x45 = 0d61 = 0b(0100 0101)
	//-- static upper 6 bits = 0b010001 - lower 2 bits = sw value.

   // signal declaration
   reg [1:0] state_reg, state_next;
   wire [7:0] rx_data;
   reg [7:0] w_data, ascii_code;
   wire psrx_done_tick, wr_ps2;
   reg wr_uart;
   wire [3:0] hex_in;
	wire reset,ps2d,ps2c;
	wire [1:0] sw, btn;
	wire [5:0] constant_din;
	
	assign sw = ~sw_n;
	assign btn = ~btn_n;	
	assign reset = btn[0];
	assign constant_din = 6'b010001;  //This is that 6 bits concatentated with the low bits of the switch.
   // body
   //====================================================
   // instantiation
   //====================================================
   // instantiate ps2 transmitter/receiver
   ps2_rxtx ps2_rxtx_unit
      (.clk(clk), 
		.reset(reset), 
		.wr_ps2(wr_ps2),
       .din( {constant_din, sw} ), 
		 .dout(rx_data), 
		 .ps2d(ps2d_1), 
		 .ps2c(ps2c_1),
       .rx_done_tick(psrx_done_tick), 
		 .tx_done_tick()
		 );

   // instantiate UART (only use the UART transmitter)
   uart uart_unit
      (.clk(clk), 
		.reset(reset), 
		.rd_uart(1'b0),
       .wr_uart(wr_uart), 
		 .rx(1'b1), 
		 .w_data(w_data),
       .tx_full(), 
		 .rx_empty(), 
		 .r_data(), 
		 .tx(tx)
		 );

   // instantiate debounce circuit
   debounce btn_db_unit
      (.clk(clk), 
		.reset(reset), 
		.sw(btn[1]),
       .db_level(), 
		 .db_tick(wr_ps2)
		 );

   //====================================================
   // FSM to send 3 ASCII characters
   //====================================================
   // state registers
   always @(posedge clk, posedge reset)
      if (reset)
         state_reg <= idle;
      else
         state_reg <= state_next;

   // next-state logic
   always @*
   begin
      wr_uart = 1'b0;
      w_data = SP;
      state_next = state_reg;
      case (state_reg)
         idle:
            if (psrx_done_tick) // a scan code received
               state_next = send1;
         send1: // send higher hex char
            begin
               w_data = ascii_code;
               wr_uart = 1'b1;
               state_next = send0;
            end
         send0: // send lower hex char
            begin
               w_data = ascii_code;
               wr_uart = 1'b1;
               state_next = sendb;
            end
         sendb:  // send blank char
            begin
               w_data = SP;
               wr_uart = 1'b1;
               state_next = idle;
            end
      endcase
   end

   //====================================================
   // scan code to ASCII display
   //====================================================
   // split the scan code into two 4-bit hex
   assign hex_in = (state_reg==send1)? rx_data[7:4] :
                                       rx_data[3:0];
   // hex digit to ASCII code
   always @*
    case (hex_in)
       4'h0: ascii_code = 8'h30;
       4'h1: ascii_code = 8'h31;
       4'h2: ascii_code = 8'h32;
       4'h3: ascii_code = 8'h33;
       4'h4: ascii_code = 8'h34;
       4'h5: ascii_code = 8'h35;
       4'h6: ascii_code = 8'h36;
       4'h7: ascii_code = 8'h37;
       4'h8: ascii_code = 8'h38;
       4'h9: ascii_code = 8'h39;
       4'ha: ascii_code = 8'h41;
       4'hb: ascii_code = 8'h42;
       4'hc: ascii_code = 8'h43;
       4'hd: ascii_code = 8'h44;
       4'he: ascii_code = 8'h45;
       default: ascii_code = 8'h46;
    endcase

endmodule
