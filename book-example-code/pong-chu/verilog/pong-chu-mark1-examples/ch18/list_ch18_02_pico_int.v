// Listing 18.2
module pico_int
   (
    input wire clk, reset,
    input wire [7:0] sw,
    input wire [1:0] btn,
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
   wire interrupt, interrupt_ack;
   // I/O port signals
   // output enable
   reg [1:0] en_d;
   // four-digit seven-segment led display
   reg [7:0] sseg_reg;
   reg [3:0] an_reg;
   // two pushbuttons
   reg btnc_flag_reg, btns_flag_reg;
   wire btnc_flag_next, btns_flag_next;
   wire set_btnc_flag, set_btns_flag, clr_btn_flag;
   // interrupt related signals
   reg [8:0] timer_reg;
   wire [8:0] timer_next;
   wire ten_us_tick;
   reg timer_flag_reg;
   wire timer_flag_next;

   //body
   // =====================================================
   //  I/O modules
   // =====================================================
   debounce btnc_unit
      (.clk(clk), .reset(reset), .sw(btn[0]),
       .db_level(), .db_tick(set_btnc_flag));
   debounce btns_unit
      (.clk(clk), .reset(reset), .sw(btn[1]),
       .db_level(), .db_tick(set_btns_flag));
   // =====================================================
   //  KCPSM and ROM instantiation
   // =====================================================
   kcpsm3 proc_unit
      (.clk(clk), .reset(1'b0), .address(address),
       .instruction(instruction), .port_id(port_id),
       .write_strobe(write_strobe), .out_port(out_port),
       .read_strobe(read_strobe), .in_port(in_port),
       .interrupt(interrupt), .interrupt_ack(interrupt_ack));
   int_rom rom_unit
      (.clk(clk), .address(address),
       .instruction(instruction));
   // =====================================================
   //  output interface
   // =====================================================
   //    outport port id:
   //      0x00: an
   //      0x01: ssg
   // =====================================================
   // registers
   always @(posedge clk)
      begin
         if (en_d[0])
            an_reg <= out_port[3:0];
         if (en_d[1])
            sseg_reg <= out_port;
      end
   assign an = an_reg;
   assign sseg = sseg_reg;
   // decoding circuit for enable signals
   always @*
      if (write_strobe)
         case (port_id[0])
            1'b0: en_d = 2'b01;
            1'b1: en_d = 2'b10;
         endcase
      else
         en_d = 2'b00;
   // =====================================================
   //  input interface
   // =====================================================
   //    input port id
   //      0x00: flag
   //      0x01: switch
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
   assign clr_btn_flag = read_strobe && (port_id[0]==1'b0);
   // input multiplexing
   always @*
      case(port_id[0])
         1'b0: in_port = {6'b0, btns_flag_reg, btnc_flag_reg};
         1'b1: in_port = sw;
      endcase

   // =====================================================
   //  interrupt interface
   // =====================================================
   // 10 us counter
   always @(posedge clk)
      timer_reg <= timer_next;
   assign ten_us_tick = (timer_reg==499);
   assign timer_next = ten_us_tick ? 0 : timer_reg + 1;
   // 10 us tick flag
   always @(posedge clk)
       timer_flag_reg <= timer_flag_next;
   assign timer_flag_next = (ten_us_tick) ? 1'b1 :
                            (interrupt_ack) ? 1'b0 :
                             timer_flag_reg;
   // interrupt request
   assign interrupt = timer_flag_reg;

endmodule
