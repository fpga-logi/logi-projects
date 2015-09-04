// Blink two LEDs
// (c) KNJN LLC - fpga4fun.com

module logipi_gpio(OSC_FPGA, LED, rpi_gpio);
input OSC_FPGA;
input rpi_gpio;
output [1:0] LED;

reg [31:0] cnt;
always @(posedge OSC_FPGA) cnt <= cnt + 32'h1;
assign LED[0] = ~cnt[22] & ~cnt[20];
// LED1 depends on RPi GPIO
assign LED[1] = cnt[25-(rpi_gpio << 2)];
endmodule