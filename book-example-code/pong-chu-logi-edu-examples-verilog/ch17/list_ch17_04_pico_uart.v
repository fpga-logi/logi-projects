// Listing 17.4
module pico_uart
   (
    input wire clk, reset,
    input wire [7:0] sw,
    input wire rx,
    input wire [1:0] btn,
    output wire tx,
    output wire [3:0] an,
    output wire [7:0] sseg
   );

   // signal declaration
   // KCPSM3/ROM signals
   wire [9:0] address;
   wire [17:0] instruction;
   wire [7:0] port_id, out_port;
   reg [7:0] in_port;
   wire  write_strobe, read_strobe;
   // I/O port signals
   // output enable
   reg [6:0] en_d;
   // four-digit seven-segment led display
   reg [7:0] ds3_reg, ds2_reg, ds1_reg, ds0_reg;
   // two pushbuttons
   reg btnc_flag_reg, btns_flag_reg;
   wire btnc_flag_next, btns_flag_next;
   wire set_btnc_flag, set_btns_flag, clr_btn_flag;
   // uart
   wire [7:0] rx_char;
   wire rd_uart, rx_not_empty, rx_empty;
   wire wr_uart, tx_full;
   // multiplier
   reg [7:0] m_src0_reg, m_src1_reg;
   wire [15:0] prod;


   //body
   // =====================================================
   //  I/O modules
   // =====================================================
   disp_mux disp_unit
      (.clk(clk), .reset(reset),
       .in3(ds3_reg), .in2(ds2_reg), .in1(ds1_reg),
       .in0(ds0_reg), .an(an), .sseg(sseg));
   debounce btnc_unit
      (.clk(clk), .reset(reset), .sw(btn[0]),
       .db_level(), .db_tick(set_btnc_flag));
   debounce btns_unit
      (.clk(clk), .reset(reset), .sw(btn[1]),
       .db_level(), .db_tick(set_btns_flag));
   uart uart_unit
      (.clk(clk), .reset(reset), .rd_uart(rd_uart),
       .wr_uart(wr_uart), .rx(rx),
       .w_data(out_port), .tx_full(tx_full),
       .rx_empty(rx_empty), .r_data(rx_char), .tx(tx));
   // combinational multiplier
   assign prod = m_src0_reg * m_src1_reg;
   // =====================================================
   //  KCPSM and ROM instantiation
   // =====================================================
   kcpsm3 proc_unit
      (.clk(clk), .reset(1'b0), .address(address),
       .instruction(instruction), .port_id(port_id),
       .write_strobe(write_strobe), .out_port(out_port),
       .read_strobe(read_strobe), .in_port(in_port),
       .interrupt(1'b0), .interrupt_ack());
   uart_rom rom_unit
      (.clk(clk), .address(address),
       .instruction(instruction));
   // =====================================================
   //  output interface
   // =====================================================
   //    outport port id:
   //      0x00: ds0
   //      0x01: ds1
   //      0x02: ds2
   //      0x03: ds3
   //      0x04: uart_tx_fifo
   //      0x05: m_src0
   //      0x06: m_src1
   // =====================================================
   // registers
   always @(posedge clk)
      begin
         if (en_d[0])
            ds0_reg <= out_port;
         if (en_d[1])
            ds1_reg <= out_port;
         if (en_d[2])
            ds2_reg <= out_port;
         if (en_d[3])
            ds3_reg <= out_port;
         if (en_d[5])
            m_src0_reg <= out_port;
         if (en_d[6])
            m_src1_reg <= out_port;
      end

   // decoding circuit for enable signals
   always @*
      if (write_strobe)
         case (port_id[2:0])
            3'b000: en_d = 7'b0000001;
            3'b001: en_d = 7'b0000010;
            3'b010: en_d = 7'b0000100;
            3'b011: en_d = 7'b0001000;
            3'b100: en_d = 7'b0010000;
            3'b101: en_d = 7'b0100000;
            default: en_d = 7'b1000000;
         endcase
      else
         en_d = 7'b0000000;

   assign wr_uart = en_d[4];
   // =====================================================
   //  input interface
   // =====================================================
   //    input port id
   //      0x00: flag
   //      0x01: switch
   //      0x02: uart_rx_fifo
   //      0x03: prod lower byte
   //      0x04: prod upper byte
   // =====================================================
   // input register (for flags)
   always @(posedge clk)
      begin
         btnc_flag_reg <= btnc_flag_next;
         btns_flag_reg <= btns_flag_next;
      end
   assign btnc_flag_next = (set_btnc_flag) ? 1'b1 :
                           (clr_btn_flag)  ? 1'b0 :
                            btnc_flag_reg;
   assign btns_flag_next = (set_btns_flag) ? 1'b1 :
                           (clr_btn_flag)  ? 1'b0 :
                            btns_flag_reg;

   // decoding circuit for clear signals
   assign clr_btn_flag = read_strobe && (port_id[2:0]==3'b000);
   assign rd_uart = read_strobe && (port_id[2:0]==3'b010);
   // input multiplexing
   assign rx_not_empty = ~rx_empty;
   always @*
      case(port_id[2:0])
         3'b000: in_port = {4'b0, tx_full, rx_not_empty,
                            btns_flag_reg, btnc_flag_reg};
         3'b001: in_port = sw;
         3'b010: in_port = rx_char;
         3'b011: in_port = prod[7:0];
         default: in_port = prod[15:8];
      endcase

endmodule
