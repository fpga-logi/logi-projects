library ieee;
use ieee.std_logic_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

library work ;
use work.logi_wishbone_pack.all ;
use work.logi_wishbone_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;
use work.control_pack.all ;


entity test_ugv is
	port(
		OSC_FPGA : in std_logic ;
		MOSI :  in std_logic;
		MISO :   out  std_logic;
		SS :  in std_logic;
		SCK :  in std_logic;
		LED :   out  std_logic_vector((2-1) downto 0);
		PMOD1 :   inout  std_logic_vector((8-1) downto 0);
		PMOD2 :   inout  std_logic_vector((8-1) downto 0);
		PMOD3 :   inout  std_logic_vector((8-1) downto 0);
		PMOD4 :   inout  std_logic_vector((8-1) downto 0);
		ARD :   inout  std_logic_vector((6-1) downto 0);
		PB :  in std_logic_vector((2-1) downto 0);
		SW :  in std_logic_vector((2-1) downto 0)	
	);
end test_ugv;

architecture structural of test_ugv is
	
	type wishbone_bus is
	record
		address : std_logic_vector(15 downto 0);
		writedata : std_logic_vector(15 downto 0);
		readdata : std_logic_vector(15 downto 0);
		cycle: std_logic;
		write : std_logic;
		strobe : std_logic;
		ack : std_logic;
	end record;

	signal gls_clk, gls_reset, clk_locked, osc_buff, clkfb : std_logic ;

	signal Master_0_wbm_Intercon_0_wbs : wishbone_bus;
	signal top_MOSI_Master_0_mosi : std_logic;
	signal top_SS_Master_0_ss : std_logic;
	signal top_SCK_Master_0_sck : std_logic;
	signal Master_0_miso_top_MISO : std_logic;
	signal Intercon_0_wbm_GPIO_0_wbs : wishbone_bus;
	signal Intercon_0_wbm_PWM_0_wbs : wishbone_bus;
	signal Intercon_0_wbm_Servo_0_wbs : wishbone_bus;
	signal Intercon_0_wbm_watchdog_0_wbs : wishbone_bus;
	signal watchdog_0_reset_out_Servo_0_failsafe : std_logic;
	signal Servo_0_servos_top_ARD : std_logic_vector((2-1) downto 0);
	signal PWM_0_pwm_out_top_PMOD2 : std_logic_vector((3-1) downto 0);
	signal GPIO_0_gpio_top_PMOD1 : std_logic_vector((8-1) downto 0);
	signal beat_0_beat_out_top_LED : std_logic;

begin


gls_reset <= (NOT clk_locked); -- system reset while clock not locked



Master_0 : spi_wishbone_wrapper
-- no generics
port map(
	gls_clk => gls_clk, gls_reset => gls_reset,

mosi =>  top_MOSI_Master_0_mosi
,

miso =>  Master_0_miso_top_MISO
,

ss =>  top_SS_Master_0_ss
,

sck =>  top_SCK_Master_0_sck
,

wbm_address =>  Master_0_wbm_Intercon_0_wbs.address,
wbm_writedata =>  Master_0_wbm_Intercon_0_wbs.writedata,
wbm_readdata =>  Master_0_wbm_Intercon_0_wbs.readdata,
wbm_cycle =>  Master_0_wbm_Intercon_0_wbs.cycle,
wbm_strobe =>  Master_0_wbm_Intercon_0_wbs.strobe,
wbm_write =>  Master_0_wbm_Intercon_0_wbs.write,
wbm_ack =>  Master_0_wbm_Intercon_0_wbs.ack	
);

Intercon_0 : wishbone_intercon
generic map(
memory_map => ("000000000000000X", "000000000001XXXX", "000000000010XXXX", "000000000000001X")
)
port map(
	gls_clk => gls_clk, gls_reset => gls_reset,

wbs_address =>  Master_0_wbm_Intercon_0_wbs.address,
wbs_writedata =>  Master_0_wbm_Intercon_0_wbs.writedata,
wbs_readdata =>  Master_0_wbm_Intercon_0_wbs.readdata,
wbs_cycle =>  Master_0_wbm_Intercon_0_wbs.cycle,
wbs_strobe =>  Master_0_wbm_Intercon_0_wbs.strobe,
wbs_write =>  Master_0_wbm_Intercon_0_wbs.write,
wbs_ack =>  Master_0_wbm_Intercon_0_wbs.ack,

wbm_address(0) =>  Intercon_0_wbm_GPIO_0_wbs.address,
wbm_address(1) =>  Intercon_0_wbm_PWM_0_wbs.address,
wbm_address(2) =>  Intercon_0_wbm_Servo_0_wbs.address,
wbm_address(3) =>  Intercon_0_wbm_watchdog_0_wbs.address,
wbm_writedata(0) =>  Intercon_0_wbm_GPIO_0_wbs.writedata,
wbm_writedata(1) =>  Intercon_0_wbm_PWM_0_wbs.writedata,
wbm_writedata(2) =>  Intercon_0_wbm_Servo_0_wbs.writedata,
wbm_writedata(3) =>  Intercon_0_wbm_watchdog_0_wbs.writedata,
wbm_readdata(0) =>  Intercon_0_wbm_GPIO_0_wbs.readdata,
wbm_readdata(1) =>  Intercon_0_wbm_PWM_0_wbs.readdata,
wbm_readdata(2) =>  Intercon_0_wbm_Servo_0_wbs.readdata,
wbm_readdata(3) =>  Intercon_0_wbm_watchdog_0_wbs.readdata,
wbm_cycle(0) =>  Intercon_0_wbm_GPIO_0_wbs.cycle,
wbm_cycle(1) =>  Intercon_0_wbm_PWM_0_wbs.cycle,
wbm_cycle(2) =>  Intercon_0_wbm_Servo_0_wbs.cycle,
wbm_cycle(3) =>  Intercon_0_wbm_watchdog_0_wbs.cycle,
wbm_strobe(0) =>  Intercon_0_wbm_GPIO_0_wbs.strobe,
wbm_strobe(1) =>  Intercon_0_wbm_PWM_0_wbs.strobe,
wbm_strobe(2) =>  Intercon_0_wbm_Servo_0_wbs.strobe,
wbm_strobe(3) =>  Intercon_0_wbm_watchdog_0_wbs.strobe,
wbm_write(0) =>  Intercon_0_wbm_GPIO_0_wbs.write,
wbm_write(1) =>  Intercon_0_wbm_PWM_0_wbs.write,
wbm_write(2) =>  Intercon_0_wbm_Servo_0_wbs.write,
wbm_write(3) =>  Intercon_0_wbm_watchdog_0_wbs.write,
wbm_ack(0) =>  Intercon_0_wbm_GPIO_0_wbs.ack,
wbm_ack(1) =>  Intercon_0_wbm_PWM_0_wbs.ack,
wbm_ack(2) =>  Intercon_0_wbm_Servo_0_wbs.ack,
wbm_ack(3) =>  Intercon_0_wbm_watchdog_0_wbs.ack	
);

GPIO_0 : wishbone_gpio
-- no generics
port map(
	gls_clk => gls_clk, gls_reset => gls_reset,

wbs_address =>  Intercon_0_wbm_GPIO_0_wbs.address,
wbs_writedata =>  Intercon_0_wbm_GPIO_0_wbs.writedata,
wbs_readdata =>  Intercon_0_wbm_GPIO_0_wbs.readdata,
wbs_cycle =>  Intercon_0_wbm_GPIO_0_wbs.cycle,
wbs_strobe =>  Intercon_0_wbm_GPIO_0_wbs.strobe,
wbs_write =>  Intercon_0_wbm_GPIO_0_wbs.write,
wbs_ack =>  Intercon_0_wbm_GPIO_0_wbs.ack,

gpio(7 downto 0) =>  GPIO_0_gpio_top_PMOD1
,
gpio(15 downto 8) => open
	
);

PWM_0 : wishbone_pwm
generic map(
nb_chan => 7
)
port map(
	gls_clk => gls_clk, gls_reset => gls_reset,

wbs_address =>  Intercon_0_wbm_PWM_0_wbs.address,
wbs_writedata =>  Intercon_0_wbm_PWM_0_wbs.writedata,
wbs_readdata =>  Intercon_0_wbm_PWM_0_wbs.readdata,
wbs_cycle =>  Intercon_0_wbm_PWM_0_wbs.cycle,
wbs_strobe =>  Intercon_0_wbm_PWM_0_wbs.strobe,
wbs_write =>  Intercon_0_wbm_PWM_0_wbs.write,
wbs_ack =>  Intercon_0_wbm_PWM_0_wbs.ack,

pwm_out(2 downto 0) =>  PWM_0_pwm_out_top_PMOD2
,
pwm_out(6 downto 3) => open
	
);

Servo_0 : wishbone_servo
generic map(
nb_servos => 8
)
port map(
	gls_clk => gls_clk, gls_reset => gls_reset,

wbs_address =>  Intercon_0_wbm_Servo_0_wbs.address,
wbs_writedata =>  Intercon_0_wbm_Servo_0_wbs.writedata,
wbs_readdata =>  Intercon_0_wbm_Servo_0_wbs.readdata,
wbs_cycle =>  Intercon_0_wbm_Servo_0_wbs.cycle,
wbs_strobe =>  Intercon_0_wbm_Servo_0_wbs.strobe,
wbs_write =>  Intercon_0_wbm_Servo_0_wbs.write,
wbs_ack =>  Intercon_0_wbm_Servo_0_wbs.ack,

failsafe =>  watchdog_0_reset_out_Servo_0_failsafe
,

servos(1 downto 0) =>  Servo_0_servos_top_ARD
,
servos(7 downto 2) => open
	
);

watchdog_0 : wishbone_watchdog
-- no generics
port map(
	gls_clk => gls_clk, gls_reset => gls_reset,

wbs_address =>  Intercon_0_wbm_watchdog_0_wbs.address,
wbs_writedata =>  Intercon_0_wbm_watchdog_0_wbs.writedata,
wbs_readdata =>  Intercon_0_wbm_watchdog_0_wbs.readdata,
wbs_cycle =>  Intercon_0_wbm_watchdog_0_wbs.cycle,
wbs_strobe =>  Intercon_0_wbm_watchdog_0_wbs.strobe,
wbs_write =>  Intercon_0_wbm_watchdog_0_wbs.write,
wbs_ack =>  Intercon_0_wbm_watchdog_0_wbs.ack,

reset_out =>  watchdog_0_reset_out_Servo_0_failsafe
	
);

beat_0 : heart_beat
-- no generics
port map(
	gls_clk => gls_clk, gls_reset => gls_reset,

beat_out =>  beat_0_beat_out_top_LED
	
);



-- Connecting inputs
top_MOSI_Master_0_mosi <= MOSI;
top_SS_Master_0_ss <= SS;
top_SCK_Master_0_sck <= SCK;
-- <= PB;
-- <= SW;

-- Connecting outputs
MISO <= Master_0_miso_top_MISO;
LED(0) <= beat_0_beat_out_top_LED and (not watchdog_0_reset_out_Servo_0_failsafe);
LED(1) <= ARD(2);

-- Connecting inouts
PMOD1(7 downto 0) <= GPIO_0_gpio_top_PMOD1;
PMOD2(2 downto 0) <= PWM_0_pwm_out_top_PMOD2;
PMOD2 <= (others => 'Z');
PMOD3 <= (others => 'Z');
PMOD4 <= (others => 'Z');
ARD(1 downto 0) <= Servo_0_servos_top_ARD;

ARD <= (others => 'Z');





-- system clock generation

PLL_BASE_inst : PLL_BASE generic map (
      BANDWIDTH      => "OPTIMIZED",        -- "HIGH", "LOW" or "OPTIMIZED" 
      CLKFBOUT_MULT  => 16 ,                 -- Multiply value for all CLKOUT clock outputs (1-64)
      CLKFBOUT_PHASE => 0.0,                -- Phase offset in degrees of the clock feedback output (0.0-360.0).
      CLKIN_PERIOD   => 20.00,              -- Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
      CLKOUT0_DIVIDE => 8,       CLKOUT1_DIVIDE => 1,
      CLKOUT2_DIVIDE => 1,       CLKOUT3_DIVIDE => 1,
      CLKOUT4_DIVIDE => 1,       CLKOUT5_DIVIDE => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5, CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5, CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5, CLKOUT5_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Output phase relationship for CLKOUT# clock output (-360.0-360.0).
      CLKOUT0_PHASE => 0.0,      CLKOUT1_PHASE => 0.0, -- Capture clock
      CLKOUT2_PHASE => 0.0,      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,      CLKOUT5_PHASE => 0.0,
      
      CLK_FEEDBACK => "CLKFBOUT",           -- Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
      COMPENSATION => "SYSTEM_SYNCHRONOUS", -- "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL" 
      DIVCLK_DIVIDE => 1,                   -- Division value for all output clocks (1-52)
      REF_JITTER => 0.1,                    -- Reference Clock Jitter in UI (0.000-0.999).
      RESET_ON_LOSS_OF_LOCK => FALSE        -- Must be set to FALSE
   ) port map (
      CLKFBOUT => clkfb, -- 1-bit output: PLL_BASE feedback output
      -- CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
      CLKOUT0 => gls_clk,      CLKOUT1 => open,
      CLKOUT2 => open,      CLKOUT3 => open,
      CLKOUT4 => open,      CLKOUT5 => open,
      LOCKED  => clk_locked,  -- 1-bit output: PLL_BASE lock status output
      CLKFBIN => clkfb, -- 1-bit input: Feedback clock input
      CLKIN   => osc_buff,  -- 1-bit input: Clock input
      RST     => '0'    -- 1-bit input: Reset input
   );

    -- Buffering of clocks
	BUFG_1 : BUFG port map (O => osc_buff,    I => OSC_FPGA);

end structural ;
