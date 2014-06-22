// Listing 17.2
module pico_btn
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
   // I/O port signals
   // output enable
   reg [3:0] en_d;
   // four-digit seven-segment led display
   reg [7:0] ds3_reg, ds2_reg, ds1_reg, ds0_reg;
   // two pushbuttons
   reg btnc_flag_reg, btns_flag_reg;
   wire btnc_flag_next, btns_flag_next;
   wire set_btnc_flag, set_btns_flag, clr_btn_flag;

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
   // =====================================================
   //  KCPSM and ROM instantiation
   // =====================================================
   kcpsm3 proc_unit
      (.clk(clk), .reset(1'b0), .address(address),
       .instruction(instruction), .port_id(port_id),
       .write_strobe(write_strobe), .out_port(out_port),
       .read_strobe(read_strobe), .in_port(in_port),
         .interrupt(1'b0), .interrupt_ack());
   btn_rom rom_unit
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
      end
   // decoding circuit for enable signals
   always @*
      if (write_strobe)
         case (port_id[1:0])
            2'b00: en_d = 4'b0001;
            2'b01: en_d = 4'b0010;
            2'b10: en_d = 4'b0100;
            2'b11: en_d = 4'b1000;
         endcase
      else
         en_d = 4'b0000;

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

endmodule
