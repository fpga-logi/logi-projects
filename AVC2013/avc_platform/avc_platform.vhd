----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:14:22 06/21/2012 
-- Design Name: 
-- Module Name:    spartcam_beaglebone - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

library work ;
use work.utils_pack.all ;
use work.peripheral_pack.all ;
use work.interface_pack.all ;
use work.conf_pack.all ;
use work.image_pack.all ;
use work.blob_pack.all ;
use work.classifier_pack.all ;
use work.primitive_pack.all ;


-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity avc_platform is
port( OSC_FPGA : in std_logic;

		--onboard
		PB, DIP_SW : in std_logic_vector(3 downto 0);
		LED : out std_logic_vector(7 downto 0);	
		
			--PMOD
		PMOD4_6, PMOD4_2  : inout std_logic ; -- used as SCL, SDA
		PMOD4_0, PMOD4_3 : out std_logic ; -- used as reset and xclk 
		PMOD4_7, PMOD4_1, PMOD4_5, PMOD4_4 : in std_logic ; -- used as pclk, href, vsync
		PMOD3 : in std_logic_vector(7 downto 0); -- used as cam data
		
		PWM : out std_logic_vector(1 downto 0);
		ENC_A : in std_logic_vector(1 downto 0);
		ENC_B : in std_logic_vector(1 downto 0);
		
		--i2c
		SYS_I2C_SCL, SYS_I2C_SDA : inout std_logic ;
		
		--spi
		SYS_SPI_SCK, SYS_SPI_SS, SYS_SPI_MOSI : in std_logic ;
		SYS_SPI_MISO : out std_logic 
);
end avc_platform;

architecture Behavioral of avc_platform is

-- Component declaration
	COMPONENT clock_gen
	PORT(
		CLK_IN1 : IN std_logic;          
		CLK_OUT1 : OUT std_logic;
		CLK_OUT2 : OUT std_logic;
		CLK_OUT3 : OUT std_logic;
		LOCKED : OUT std_logic
		);
	END COMPONENT;
	
	component clock_divider is
	generic(
	 slow_clock_period   : integer := 20000000;
	 system_clock_period : integer := 50
	 );
	port (clk     : in  std_logic;
		  rst     : in  std_logic;
		  pwm_clk : out std_logic;
		  pwm_rst : out std_logic);
	end component;
	
	component servo_controller is
	generic(
	 clock_period             : integer := 32;
	 minimum_high_pulse_width : integer := 1000000;
	 maximum_high_pulse_width : integer := 2000000
	 );
	port (clk            : in  std_logic;
		  rst            : in  std_logic;
		  servo_position : in  std_logic_vector (0 to 7);
		  servo_out       : out std_logic);
	end component;
	
	

	-- Constant declaration
	constant system_clk_freq : integer      := 120_000_000;
	constant system_clk_period_ns : integer := (1000000000 / system_clk_freq);  -- convert frequency to period
   constant system_clk_period_ps : integer := (system_clk_period_ns * 1000);
	constant servo_clock_period_ps : integer := 32000;
	constant servo_clock_period_ns : integer := servo_clock_period_ps /1000;
	-- Systemc clocking and reset
	signal clk_sys, clk_100, clk_24, clk_locked : std_logic ;
	signal resetn , sys_resetn : std_logic ;
	
	
	-- Led counter
	signal counter_output : std_logic_vector(31 downto 0);
	
	
	--Memory interface signals
	signal bus_data_in, bus_data_out : std_logic_vector(15 downto 0);
	signal bus_addr : std_logic_vector(15 downto 0);
	signal bus_wr, bus_rd, bus_cs : std_logic ;
	
	-- Peripheral output signals
	signal bus_color_lut_data_out : std_logic_vector(15 downto 0);
	signal bus_blob_fifo_out : std_logic_vector(15 downto 0);
	signal bus_latches_data_out : std_logic_vector(15 downto 0);
	
	-- Peripheral logic side input signals
	signal blob_fifo_input : std_logic_vector(15 downto 0);
	signal blob_fifo_wr : std_logic ;
	
	
	-- Peripheral chip select
	signal cs_blob_fifo, cs_color_lut, cs_latches : std_logic ;
	
	
	-- Camera configuration and interface signals
	signal cam_data : std_logic_vector(7 downto 0);
	signal cam_sioc, cam_siod : std_logic ;
	signal cam_xclk, cam_pclk, cam_vsync, cam_href, cam_reset : std_logic ;
	signal rom_addr : std_logic_vector(7 downto 0);
	signal rom_data : std_logic_vector(15 downto 0);
	
	
	--Pixel pipeline signals
	signal pixel_y_from_interface, pixel_u_from_interface, pixel_v_from_interface : std_logic_vector(7 downto 0);
	signal pxclk_from_interface, href_from_interface, vsync_from_interface : std_logic ;
	signal pixel_from_bin : std_logic_vector(7 downto 0);
	signal pxclk_from_bin, href_from_bin, vsync_from_bin : std_logic ;
	signal pixel_from_erode : std_logic_vector(7 downto 0);
	signal pxclk_from_erode, href_from_erode, vsync_from_erode : std_logic ;
	
	-- Classifier signals
	signal color_index : std_logic_vector(15 downto 0);
	signal color_lut_out : std_logic_vector(7 downto 0);
	
	-- PWM related signals
	signal pwm_value_1, pwm_value_0 : std_logic_vector(15 downto 0);
	signal enc_value_1, enc_value_0 : std_logic_vector(31 downto 0);
	signal pwm_clk, pwm_rst : std_logic ;
	
	-- Encoders related signal
	signal ENC_A_OLD, ENC_A_RE  : std_logic_vector(1 downto 0); 
	
	for all : yuv_register_rom use entity work.yuv_register_rom(ov7725_qvga);
begin
	
	resetn <= PB(0) ;
	
	sys_clocks_gen: clock_gen 
	PORT MAP(
		CLK_IN1 => OSC_FPGA,
		CLK_OUT1 => clk_100,
		CLK_OUT2 => clk_24,
		CLK_OUT3 => clk_sys, --120Mhz system clock
		LOCKED => clk_locked
	);


	reset0: reset_generator 
	generic map(HOLD_0 => 1000)
	port map(
		clk => clk_sys, 
		resetn => resetn ,
		resetn_0 => sys_resetn
		);


	divider : simple_counter 
	generic map(NBIT => 32)
	port map(
		clk => clk_sys, 
		resetn => sys_resetn, 
		sraz => '0',
		en => '1',
		load => '0' ,
		E => X"00000000",
		Q => counter_output
		);
		  
		  
	LED(0) <= counter_output(24);


-- Memory interface instantiation
	mem_interface0 : spi2ad_bus
		generic map(ADDR_WIDTH => 16 , DATA_WIDTH =>  16)
		port map(
			clk => clk_sys ,
			resetn => sys_resetn ,
			mosi => SYS_SPI_MOSI,
			miso => SYS_SPI_MISO,
			sck => SYS_SPI_SCK,
			ss => SYS_SPI_SS,
			data_bus_out	=> bus_data_out,
			data_bus_in	=> bus_data_in ,
			addr_bus	=> bus_addr, 
			wr => bus_wr , rd => bus_rd 
		);

-- chip select configuration
	cs_blob_fifo <= '1' when bus_addr(15 downto 3) = "0000000000000" else
				  '0' ; -- 8 * 16bit address space
				  
	cs_color_lut <= '1' when bus_addr(15 downto 12) = "0001" else
				  '0' ; -- 4096 * 16bit address space
				  
	cs_latches <= '1' when bus_addr(15 downto 3) = "0010000000000" else
				  '0' ; -- 4 * 16bit address space

	bus_data_in <= bus_blob_fifo_out when cs_blob_fifo = '1' else
						bus_color_lut_data_out when cs_color_lut = '1' else
						bus_latches_data_out when cs_latches = '1' else 
						(others => '1');
						
-- Peripherals instantiation
	fifo_blobs : fifo_peripheral 
		generic map(ADDR_WIDTH => 16,
						WIDTH => 16, 
						SIZE => 1024, 
						BURST_SIZE => 4,
						SYNC_LOGIC_INTERFACE => true)
		port map(
			clk => clk_sys,
			resetn => sys_resetn,
			addr_bus => bus_addr,
			wr_bus => bus_wr,
			rd_bus => bus_rd,
			cs_bus => cs_blob_fifo,
			wrB => blob_fifo_wr,
			rdA => '0',
			data_bus_in => bus_data_out,
			data_bus_out => bus_blob_fifo_out,
			inputB => blob_fifo_input, 
			outputA => open,
			emptyA => open,
			fullA => open,
			emptyB => open,
			fullB => open,
			burst_available_B => open
		);		
 
	addr_latches_Inst : addr_latches_peripheral
		generic map(ADDR_WIDTH => 16, WIDTH => 16, NB => 8)
		port map(
			clk => clk_sys, resetn => sys_resetn,
			addr_bus => bus_addr, 
			wr_bus => bus_wr, 
			rd_bus => bus_rd, 
			cs_bus => cs_latches,
			data_bus_in	=> bus_data_out,
			data_bus_out => bus_latches_data_out,
			latch_input(0) => pwm_value_0,
			latch_input(1) => pwm_value_1,
			latch_input(2) => enc_value_0(15 downto 0),
			latch_input(3) => enc_value_0(31 downto 16),
			latch_input(4) => enc_value_1(15 downto 0),
			latch_input(5) => enc_value_1(31 downto 16),
			latch_input(6) => (others => '0'), -- for future use
			latch_input(7) => (others => '0'), -- for future use
			latch_output(0) => pwm_value_0,
			latch_output(1) => pwm_value_1,
			latch_output(2)(7 downto 1) => LED(7 downto 1),
			latch_output(2)(0) =>  open,
			latch_output(3) => open,
			latch_output(4) => open,
			latch_output(5) => open,
			latch_output(6) => open,
			latch_output(7) => open
		);
		
	classifier_lut : dpram_NxN	
		generic map(SIZE => 4096, NBIT => 2, ADDR_WIDTH => 12)
		port map(
			clk => clk_sys ,
			we =>  (bus_wr AND cs_color_lut),
			
			di => bus_data_out(1 downto 0), 
			a	=> bus_addr(11 downto 0),
			dpra => color_index(11 downto 0),
			spo => bus_color_lut_data_out(1 downto 0),
			dpo => color_lut_out(1 downto 0) 		
		); 
	bus_color_lut_data_out(15 downto 2) <= (others => '0');
 
-- Camera Interface and configuration instantiation 
	conf_rom : yuv_register_rom
		port map(
			clk => clk_sys, en => '1' ,
			data => rom_data,
			addr => rom_addr
		); 
 
	camera_conf_block : i2c_conf 
		generic map(ADD_WIDTH => 8 , SLAVE_ADD => "0100001")
		port map(
			clock => clk_sys, 
			resetn => sys_resetn ,		
			i2c_clk => clk_24 ,
			scl => PMOD4_6,
			sda => PMOD4_2, 
			reg_addr => rom_addr ,
			reg_data => rom_data
		);	
		
	camera0: yuv_camera_interface
		port map(
			clock => clk_sys,
			resetn => sys_resetn,
			pixel_data => cam_data, 
			pxclk => cam_pclk, href => cam_href, vsync => cam_vsync,
			pixel_clock_out => pxclk_from_interface, hsync_out => href_from_interface, vsync_out => vsync_from_interface,
			y_data => pixel_y_from_interface,
			u_data => pixel_u_from_interface,
			v_data => pixel_v_from_interface
					
		);	
		
	cam_xclk <= clk_24;
	PMOD4_3 <= cam_xclk ;
	--cam_data <= PMOD2 ;
	cam_data <= PMOD3(3) & PMOD3(7) & PMOD3(2) & PMOD3(6) & PMOD3(1) & PMOD3(5) & PMOD3(0) & PMOD3(4) ;
	cam_pclk <= PMOD4_7 ;
	cam_href <= PMOD4_1 ;
	cam_vsync <= PMOD4_5 ;
	PMOD4_0 <= cam_reset ;
	cam_reset <= resetn ;

	
-- Pixel Pipeline instantiation
	classification0 : color_classifier
		port map(
				clk => clk_sys, 
				resetn => sys_resetn ,
				pixel_clock => pxclk_from_interface, hsync => href_from_interface, vsync => vsync_from_interface,
				pixel_clock_out => pxclk_from_bin, hsync_out => href_from_bin, vsync_out => vsync_from_bin,
				pixel_y => pixel_y_from_interface,
				pixel_u => pixel_u_from_interface,
				pixel_v => pixel_v_from_interface,
				pixel_class => pixel_from_bin,
				
				color_index => color_index(11 downto 0),
				lut_in => color_lut_out
		);


	smooth0 : classifier_smoother 
		generic map(WIDTH => 320, HEIGHT => 240)
		port map(
				clk => clk_sys, 
				resetn => sys_resetn ,
				pixel_clock => pxclk_from_bin, hsync => href_from_bin, vsync => vsync_from_bin,
				pixel_clock_out => pxclk_from_erode, hsync_out => href_from_erode, vsync_out => vsync_from_erode,
				pixel_data_in => pixel_from_bin,
				pixel_data_out => pixel_from_erode
		);


	blob_tracker : blob_detection 
		generic map(LINE_SIZE => 320)
		port map(
				clk => clk_sys, 
				resetn => sys_resetn ,
				pixel_clock => pxclk_from_erode, hsync => href_from_erode, vsync => vsync_from_erode,
				pixel_data_in => pixel_from_erode,
				blob_data => open,
				
				--memory_interface to copy results on vsync
				mem_addr => open,
				mem_data =>blob_fifo_input,
				mem_wr => blob_fifo_wr
		);

-- Control peripheral instantiation
	Inst_clock_divider : clock_divider
		generic map (
		slow_clock_period   => servo_clock_period_PS ,
		system_clock_period => system_clk_period_ps
		)
		port map(
		clk     => clk_sys,
		rst     => (not sys_resetn),
		pwm_clk => pwm_clk,
		pwm_rst => pwm_rst
		);

	servo_controller_0_Inst : servo_controller
	  generic map(
		 clock_period => 32,
		 minimum_high_pulse_width => 1000000,
		 maximum_high_pulse_width => 2000000
		 )
	  port map(clk => pwm_clk,
			  rst => pwm_rst,
			  servo_position => pwm_value_0(7 downto 0),
			  servo_out => PWM(0));
		  
	servo_controller_1_Inst : servo_controller
	  generic map(
		 clock_period => 32,
		 minimum_high_pulse_width => 1000000,
		 maximum_high_pulse_width => 2000000
		 )
	  port map(clk => pwm_clk,
			  rst => pwm_rst,
			  servo_position => pwm_value_1(7 downto 0),
			  servo_out => PWM(1));
			  
-- Encoders counter instantiation	
	process(clk_sys, sys_resetn)
	begin
		if sys_resetn = '0' then
			ENC_A_OLD <= (others => '0');
		elsif clk_sys'event and clk_sys = '1' then
			ENC_A_OLD <= ENC_A ;
		end if ;
	end process ;
	ENC_A_RE <= ENC_A and (NOT ENC_A_OLD) ;		  
	encoder_chan0 : up_down_counter
		 generic map(NBIT => 32)
		 port map( clk => clk_sys,
					  resetn => pwm_rst,
					  sraz => '0',
					  en => ENC_A_RE(0) ,  -- must detect rising edge
					  load => '0',
					  up_downn => ENC_B(0),
					  E => (others => '0'),
					  Q => enc_value_0
					  );
	 encoder_chan1 : up_down_counter
		 generic map(NBIT => 32)
		 port map( clk => clk_sys,
					  resetn => pwm_rst,
					  sraz => '0',
					  en => ENC_A_RE(1) , -- must detect rising edge 
					  load => '0',
					  up_downn => ENC_B(1),
					  E => (others => '0'),
					  Q => enc_value_1
					  );

end Behavioral;

