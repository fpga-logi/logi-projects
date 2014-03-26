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
use UNISIM.VComponents.all;

library work ;
use work.logi_wishbone_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;

entity logi_edu_test is
port( OSC_FPGA : in std_logic;

		--onboard
		PB : in std_logic_vector(1 downto 0);
		SW : in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(1 downto 0);	
		
		PMOD3 : inout std_logic_vector(7 downto 0); 
		
		PMOD4 : inout std_logic_vector(7 downto 0); 
		
		PMOD2 : inout std_logic_vector(7 downto 0); 
		
		PMOD1 : inout std_logic_vector(7 downto 0); 
		--i2c
		SYS_SCL, SYS_SDA : inout std_logic ;
		
		--spi
		SYS_SPI_SCK, RP_SPI_CE0N, RP_SPI_CE1N, SYS_SPI_MOSI : in std_logic ;
		SYS_SPI_MISO : out std_logic
);
end logi_edu_test;

architecture Behavioral of logi_edu_test is

	component clock_gen
	port
	(-- Clock in ports
		CLK_IN1           : in     std_logic;
		-- Clock out ports
		CLK_OUT1          : out    std_logic;
		-- Status and control signals
		LOCKED            : out    std_logic
	);
	end component;
	
	component sound_440 is
		generic(clk_freq_hz : positive := 100_000_000);
		port(
		clk, reset : in std_logic ;
		sound_out : out std_logic 
		);
	end component;

	-- syscon
	signal gls_reset, gls_resetn,gls_clk, clock_locked : std_logic ;
	signal clk_100Mhz : std_logic ;

	-- wishbone intercon signals
	signal intercon_wrapper_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_strobe :  std_logic;
	signal intercon_wrapper_wbm_write :  std_logic;
	signal intercon_wrapper_wbm_ack :  std_logic;
	signal intercon_wrapper_wbm_cycle :  std_logic;

	signal intercon_reg0_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_reg0_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_reg0_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_reg0_wbm_strobe :  std_logic;
	signal intercon_reg0_wbm_write :  std_logic;
	signal intercon_reg0_wbm_ack :  std_logic;
	signal intercon_reg0_wbm_cycle :  std_logic;

	signal intercon_gpio0_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_gpio0_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_gpio0_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_gpio0_wbm_strobe :  std_logic;
	signal intercon_gpio0_wbm_write :  std_logic;
	signal intercon_gpio0_wbm_ack :  std_logic;
	signal intercon_gpio0_wbm_cycle :  std_logic;
	
	signal intercon_gpio1_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_gpio1_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_gpio1_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_gpio1_wbm_strobe :  std_logic;
	signal intercon_gpio1_wbm_write :  std_logic;
	signal intercon_gpio1_wbm_ack :  std_logic;
	signal intercon_gpio1_wbm_cycle :  std_logic;
	
	signal intercon_gpio2_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_gpio2_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_gpio2_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_gpio2_wbm_strobe :  std_logic;
	signal intercon_gpio2_wbm_write :  std_logic;
	signal intercon_gpio2_wbm_ack :  std_logic;
	signal intercon_gpio2_wbm_cycle :  std_logic;
	
	signal intercon_sseg0_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_sseg0_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_sseg0_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_sseg0_wbm_strobe :  std_logic;
	signal intercon_sseg0_wbm_write :  std_logic;
	signal intercon_sseg0_wbm_ack :  std_logic;
	signal intercon_sseg0_wbm_cycle :  std_logic;
	
	-- logic signals
	signal sseg_edu_cathode_out : std_logic_vector(4 downto 0);
	signal sseg_edu_anode_out : std_logic_vector(7 downto 0);
begin


gls_reset <= (NOT clock_locked); -- system reset while clock not locked
gls_resetn <= NOT gls_reset ; -- for preipherals with active low reset

pll0 : clock_gen
  port map
   (-- Clock in ports
    CLK_IN1 => OSC_FPGA,
    -- Clock out ports
    CLK_OUT1 => clk_100Mhz,
    -- Status and control signals
    LOCKED => clock_locked);

gls_clk <= clk_100Mhz;




mem_interface0 : spi_wishbone_wrapper
		port map(
			-- Global Signals
			gls_reset => gls_reset,
			gls_clk   => gls_clk,
			
			-- SPI signals
			mosi => SYS_SPI_MOSI,
			miso => SYS_SPI_MISO,
			sck => SYS_SPI_SCK,
			ss => RP_SPI_CE0N,
			
			  -- Wishbone interface signals
			wbm_address    => intercon_wrapper_wbm_address,  	-- Address bus
			wbm_readdata   => intercon_wrapper_wbm_readdata,  	-- Data bus for read access
			wbm_writedata 	=> intercon_wrapper_wbm_writedata,  -- Data bus for write access
			wbm_strobe     => intercon_wrapper_wbm_strobe,                      -- Data Strobe
			wbm_write      => intercon_wrapper_wbm_write,                      -- Write access
			wbm_ack        => intercon_wrapper_wbm_ack,                      -- acknowledge
			wbm_cycle      => intercon_wrapper_wbm_cycle                       -- bus cycle in progress
			);



-- Intercon -----------------------------------------------------------
-- will be generated automatically in the future

intercon0 : wishbone_intercon
generic map(memory_map => 
(
"000000000000001X", -- gpio0
"000000000000010X", -- gpio1
"00000000000010XX") -- sseg0
)
port map(
		gls_reset => gls_reset,
			gls_clk   => gls_clk,
		
		
		wbs_address    => intercon_wrapper_wbm_address,  	-- Address bus
		wbs_readdata   => intercon_wrapper_wbm_readdata,  	-- Data bus for read access
		wbs_writedata 	=> intercon_wrapper_wbm_writedata,  -- Data bus for write access
		wbs_strobe     => intercon_wrapper_wbm_strobe,                      -- Data Strobe
		wbs_write      => intercon_wrapper_wbm_write,                      -- Write access
		wbs_ack        => intercon_wrapper_wbm_ack,                      -- acknowledge
		wbs_cycle      => intercon_wrapper_wbm_cycle,                       -- bus cycle in progress
		
		-- Wishbone master signals
		wbm_address(0) => intercon_gpio0_wbm_address,
		wbm_address(1) => intercon_gpio1_wbm_address,
		wbm_address(2) => intercon_sseg0_wbm_address,
		wbm_writedata(0)  => intercon_gpio0_wbm_writedata,
		wbm_writedata(1)  => intercon_gpio1_wbm_writedata,
		wbm_writedata(2)  => intercon_sseg0_wbm_writedata,
		wbm_readdata(0)  => intercon_gpio0_wbm_readdata,
		wbm_readdata(1)  => intercon_gpio1_wbm_readdata,
		wbm_readdata(2)  => intercon_sseg0_wbm_readdata,
		wbm_strobe(0)  => intercon_gpio0_wbm_strobe,
		wbm_strobe(1)  => intercon_gpio1_wbm_strobe,
		wbm_strobe(2)  => intercon_sseg0_wbm_strobe,
		wbm_cycle(0)   => intercon_gpio0_wbm_cycle,
		wbm_cycle(1)   => intercon_gpio1_wbm_cycle,
		wbm_cycle(2)   => intercon_sseg0_wbm_cycle,
		wbm_write(0)   => intercon_gpio0_wbm_write,
		wbm_write(1)   => intercon_gpio1_wbm_write,
		wbm_write(2)   => intercon_sseg0_wbm_write,
		wbm_ack(0)      => intercon_gpio0_wbm_ack,
		wbm_ack(1)      => intercon_gpio1_wbm_ack,
		wbm_ack(2)      => intercon_sseg0_wbm_ack
		
);
									      
										  
-----------------------------------------------------------------------

gpio0 : wishbone_gpio
	 port map
	 (
			gls_reset => gls_reset,
			gls_clk   => gls_clk,


			wbs_address    => intercon_gpio0_wbm_address,  	
			wbs_readdata   => intercon_gpio0_wbm_readdata,  	
			wbs_writedata 	=> intercon_gpio0_wbm_writedata,  
			wbs_strobe     => intercon_gpio0_wbm_strobe,      
			wbs_write      => intercon_gpio0_wbm_write,    
			wbs_ack        => intercon_gpio0_wbm_ack,    
			wbs_cycle      => intercon_gpio0_wbm_cycle, 

			gpio(15 downto 8) => open, 
			gpio(7 downto 0) => PMOD1
	 );

gpio1 : wishbone_gpio
	 port map
	 (
			gls_reset => gls_reset,
			gls_clk   => gls_clk,


			wbs_address    => intercon_gpio1_wbm_address,  	
			wbs_readdata   => intercon_gpio1_wbm_readdata,  	
			wbs_writedata 	=> intercon_gpio1_wbm_writedata,  
			wbs_strobe     => intercon_gpio1_wbm_strobe,      
			wbs_write      => intercon_gpio1_wbm_write,    
			wbs_ack        => intercon_gpio1_wbm_ack,    
			wbs_cycle      => intercon_gpio1_wbm_cycle, 

			gpio(15) => PMOD4(7), 
			gpio(14) => open, 
			gpio(13 downto 9) => PMOD4(5 downto 1), 
			gpio(8) => open, 
			gpio(7 downto 0) => open
	 );	

sseg0 : wishbone_7seg4x
	 port map
	 (
			gls_reset => gls_reset,
			gls_clk   => gls_clk,

			wbs_address    => intercon_sseg0_wbm_address,  	
			wbs_readdata   => intercon_sseg0_wbm_readdata,  	
			wbs_writedata 	=> intercon_sseg0_wbm_writedata,  
			wbs_strobe     => intercon_sseg0_wbm_strobe,      
			wbs_write      => intercon_sseg0_wbm_write,    
			wbs_ack        => intercon_sseg0_wbm_ack,    
			wbs_cycle      => intercon_sseg0_wbm_cycle, 
			
			sseg_edu_cathode_out => sseg_edu_cathode_out,
			sseg_edu_anode_out => sseg_edu_anode_out
	 );

PMOD2(4) <= sseg_edu_cathode_out(0);
PMOD2(0) <= sseg_edu_cathode_out(1);
PMOD2(2) <= sseg_edu_cathode_out(2);
PMOD2(3) <= sseg_edu_cathode_out(3);
PMOD2(1) <= sseg_edu_cathode_out(4);


PMOD3(5) <= sseg_edu_anode_out(0); --A
PMOD3(4) <= sseg_edu_anode_out(1); --B
PMOD3(1) <= sseg_edu_anode_out(2); --C
PMOD2(5) <= sseg_edu_anode_out(3); --D
PMOD2(6) <= sseg_edu_anode_out(4); --E
PMOD3(6) <= sseg_edu_anode_out(5); --F
PMOD3(0) <= sseg_edu_anode_out(6); --G
PMOD2(7) <= sseg_edu_anode_out(7); --DP


sound_0: sound_440 -- generates 440hz pwm
		generic map(clk_freq_hz => 100_000_000)
		port map(
			clk => gls_clk, reset => gls_reset,
			sound_out =>  PMOD4(0)
		);
		
sound_1: sound_440 -- tricking module to produce 220hz pwm
		generic map(clk_freq_hz => 50_000_000)
		port map(
			clk => gls_clk, reset => gls_reset,
			sound_out =>  PMOD4(6)
		);
	
	
end Behavioral;

