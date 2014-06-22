// Listing 11.2
module ram_ctrl_test
   (
    input wire clk, reset,
    input wire [7:0] sw,
    input wire [2:0] btn,
    output wire [7:0] led,
    output wire [17:0] ad,
    output wire we_n, oe_n,
    inout wire [15:0] dio_a,
    output wire ce_a_n, ub_a_n, lb_a_n
   );

   // signal declaration
   wire [17:0] addr;
   wire [15:0] data_s2f;
   reg [15:0] data_f2s;
   reg mem, rw;
   reg [7:0] data_reg;
   wire [2:0] db_btn;

   // body
   // instantiation
   sram_ctrl ctrl_unit
      (.clk(clk), .reset(reset), .mem(mem), .rw(rw),
       .addr(addr), .data_f2s(data_f2s), .ready(),
       .data_s2f_r(data_s2f), .data_s2f_ur(), .ad(ad),
       .we_n(we_n), .oe_n(oe_n), .dio_a(dio_a),
       .ce_a_n(ce_a_n), .ub_a_n(ub_a_n), .lb_a_n(lb_a_n));

    debounce deb_unit0
       (.clk(clk), .reset(reset), .sw(btn[0]),
        .db_level(), .db_tick(db_btn[0]));

    debounce deb_unit1
       (.clk(clk), .reset(reset), .sw(btn[1]),
        .db_level(), .db_tick(db_btn[1]));

    debounce deb_unit2
       (.clk(clk), .reset(reset), .sw(btn[2]),
        .db_level(), .db_tick(db_btn[2]));

   // data registers
   always @(posedge clk)
      if (db_btn[0])
         data_reg <= sw;

   // address
   assign addr = {10'b0, sw};

   //
   always @*
   begin
     data_f2s = 0;
     if (db_btn[1])  // write
        begin
           mem = 1'b1;
           rw = 1'b0;
           data_f2s = {8'b0, data_reg};
        end
     else if (db_btn[2]) // read
        begin
           mem = 1'b1;
           rw = 1'b1;
        end
     else
        begin
           mem = 1'b0;
           rw = 1'b1;
        end
   end
   // output
   assign led = data_s2f[7:0];

endmodule
