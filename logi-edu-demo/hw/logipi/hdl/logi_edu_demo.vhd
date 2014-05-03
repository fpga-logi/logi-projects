----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:33:02 07/30/2013 
-- Design Name: 
-- Module Name:    logibone_wishbone - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
library UNISIM;
use UNISIM.VComponents.all;

library work ;
use work.logi_wishbone_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;
--use work.all;

entity logi_edu_demo is
port( 

		OSC_FPGA : in std_logic;
		--onboard
		PB : in std_logic_vector(1 downto 0);
		SW : in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(1 downto 0);	
		PMOD4 : inout std_logic_vector(7 downto 0); 
		PMOD3 : inout std_logic_vector(7 downto 0); 
		PMOD2 : inout std_logic_vector(7 downto 0); 
		PMOD1 : inout std_logic_vector(7 downto 0); 
		--i2c
		SYS_SCL, SYS_SDA : inout std_logic ;
		
		--spi
		SYS_SPI_SCK : inout std_logic ; 
		RP_SPI_CE0N : inout std_logic ; 
		SYS_SPI_MOSI : inout std_logic ;
		SYS_SPI_MISO : inout std_logic
);
end logi_edu_demo;

architecture Behavioral of logi_edu_demo is

	component clock_gen
	port
	(-- Clock in ports
		CLK_IN1           : in     std_logic;
		-- Clock out ports
		CLK_OUT1          : out    std_logic;
		CLK_OUT2          : out    std_logic;
		-- Status and control signals
		LOCKED            : out    std_logic
	);
	end component;
	
	component pong_top
	   port(
      clk, reset: in std_logic;
      btn: in std_logic_vector (1 downto 0);
      hsync, vsync: out std_logic;
      red, green, blue: out   std_logic_vector (2 downto 0);
		led: out std_logic_vector(1 downto 0)
   );
	end component;
	
	component sseg4x_basic
	port 
	 (	  reset    : in std_logic ;
		  clk      : in std_logic ;  
		  sseg_edu_cathode_out : out std_logic_vector(3 downto 0); -- common cathode
		  sseg_edu_anode_out : out std_logic_vector(7 downto 0) -- sseg anode	  
	 );
	 end component;
	
	component sound_440 is
		generic(clk_freq_hz : positive := 100_000_000);
		port(
		clk, reset : in std_logic ;
		en: in std_logic;
		sound_out : out std_logic 
		);
	end component;

	component vga_bar_top is
	port (
		clk: in std_logic;	
		reset: in std_logic;
		hsync, vsync: out  std_logic;
		sel: in std_logic;
		red: out std_logic_vector(2 downto 0);
		green: out std_logic_vector(2 downto 0);
		blue: out std_logic_vector(2 downto 0)
	);
	end component;

	-- syscon
	signal gls_reset, gls_resetn,gls_clk, clock_locked : std_logic ;
	signal clk_100Mhz, clk_50Mhz, vga_clk : std_logic ;

	-- logic signals
	signal sseg_edu_cathode_out : std_logic_vector(3 downto 0);
	signal sseg_edu_anode_out : std_logic_vector(7 downto 0);
	
	-- vga signals
	signal hsync_pong, vsync_pong : std_logic ;
	signal hsync_vga, vsync_vga : std_logic ;
	signal red_pong, green_pong, blue_pong: std_logic_vector (2 downto 0);
	signal red_vga, green_vga, blue_vga: std_logic_vector (2 downto 0);
	
	signal led_signal: std_logic_vector(1 downto 0);
	signal pbn: std_logic_vector(1 downto 0);
	
begin

	SYS_SPI_SCK <= 'Z';
	RP_SPI_CE0N <= 'Z'; 
	SYS_SPI_MOSI <= 'Z';
	SYS_SPI_MISO <= 'Z';
	SYS_SCL <= 'Z' ;
	SYS_SDA <= 'Z' ;
		
	pbn <= NOT(PB);	--invert the push button signals
	gls_reset <= pbn(1);

	pong: pong_top
	   port map(
      clk => vga_clk  , reset => '0',
      btn => pbn,
      hsync => hsync_pong,
		vsync => vsync_pong,
      red => red_pong, 
		green => green_pong , 
		blue => blue_pong,
		led => open
   );

	sseg : sseg4x_basic
	port map(
		clk => gls_clk, reset => '0',
		sseg_edu_cathode_out => sseg_edu_cathode_out,
		sseg_edu_anode_out  => sseg_edu_anode_out 
	);
	
	sound_0: sound_440 -- generates 440hz pwm
		generic map(clk_freq_hz => 100_000_000)
		port map(
			clk => gls_clk, 
			reset => '0',
			en => pbn(0),
			sound_out =>  PMOD4(0)
	);
		
	sound_1: sound_440 -- tricking module to produce 220
		generic map(clk_freq_hz => 50_000_000)
		port map(
			clk => gls_clk, 
			reset => '0',
			en => pbn(0),
			sound_out =>  PMOD4(6)
		);

	pll0 : clock_gen
	port map
   (-- Clock in ports
		CLK_IN1 => OSC_FPGA,
		-- Clock out ports
		CLK_OUT1 => clk_100Mhz,
		CLK_OUT2 => clk_50Mhz,
		-- Status and control signals
		LOCKED => clock_locked
	);
	gls_clk <= clk_100Mhz;
	vga_clk <= clk_50Mhz;

	vga0 : vga_bar_top
	port map(
		clk => vga_clk,	
		reset => '0',
		sel => SW(1),
		hsync => hsync_vga, vsync => vsync_vga,
		red => red_vga,
		green => green_vga,
		blue => blue_vga
	);
	
	
	process(SW, hsync_vga, vsync_vga, hsync_pong, vsync_pong, red_vga, green_vga,
				blue_vga, red_pong, green_pong, blue_pong)
	begin
		if(SW(0)='1') then
			--VGA SIGNAL MAPPING
			PMOD1(3) <= hsync_vga ;
			PMOD1(7) <= vsync_vga ;	
			PMOD1(0) <= red_vga(2);		
			PMOD1(4) <= red_vga(1);		
			PMOD3(7) <= red_vga(0); 	
			PMOD1(1) <= green_vga(2);	
			PMOD1(5) <= green_vga(1);	
			PMOD3(3) <= green_vga(0);	
			PMOD1(2) <= blue_vga(2);	
			PMOD1(6) <= blue_vga(1);	
			PMOD3(2) <= blue_vga(0);	
		else 
			--VGA SIGNAL MAPPING
			PMOD1(3) <= hsync_pong ;
			PMOD1(7) <= vsync_pong ;	
			PMOD1(0) <= red_pong(2);		
			PMOD1(4) <= red_pong(1);		
			PMOD3(7) <= red_pong(0); 	
			PMOD1(1) <= green_pong(2);	
			PMOD1(5) <= green_pong(1);	
			PMOD3(3) <= green_pong(0);	
			PMOD1(2) <= blue_pong(2);	
			PMOD1(6) <= blue_pong(1);	
			PMOD3(2) <= blue_pong(0);	
		end if;
	end process;
	
	
	PMOD2(4) <= sseg_edu_cathode_out(0); -- cathode 0
	PMOD2(0) <= sseg_edu_cathode_out(1); -- cathode 1
	PMOD2(2) <= sseg_edu_cathode_out(2); -- cathode 2
	PMOD2(3) <= sseg_edu_cathode_out(3); -- cathode 3
	--PMOD2(1) <= sseg_edu_cathode_out(4); -- cathode 4
	PMOD2(1) <= '0'; -- cathode 4

	PMOD3(5) <= sseg_edu_anode_out(0); --A
	PMOD3(4) <= sseg_edu_anode_out(1); --B
	PMOD3(1) <= sseg_edu_anode_out(2); --C
	PMOD2(5) <= sseg_edu_anode_out(3); --D
	PMOD2(6) <= sseg_edu_anode_out(4); --E
	PMOD3(6) <= sseg_edu_anode_out(5); --F
	PMOD3(0) <= sseg_edu_anode_out(6); --G
	PMOD2(7) <= sseg_edu_anode_out(7); --DP
	
	LED <= SW;

end Behavioral;

