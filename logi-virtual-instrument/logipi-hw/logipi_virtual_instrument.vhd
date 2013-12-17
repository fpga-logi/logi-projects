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
use work.logi_virtual_components_pack.all ;

entity logipi_virtual_instrument is
port( OSC_FPGA : in std_logic;

		--onboard
		PB : in std_logic_vector(1 downto 0);
		SW : in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(1 downto 0);	
		
		--i2c
		SYS_SCL, SYS_SDA : inout std_logic ;
		
		--spi
		SYS_SPI_SCK, RP_SPI_CE0N, SYS_SPI_MOSI : in std_logic ;
		SYS_SPI_MISO : out std_logic
);
end logipi_virtual_instrument;

architecture Behavioral of logipi_virtual_instrument is

	component clock_gen
	port
	(-- Clock in ports
		CLK_IN1           : in     std_logic;
		-- Clock out ports
		CLK_OUT1          : out    std_logic;
		CLK_OUT2          : out    std_logic;
		CLK_OUT3          : out    std_logic;
		-- Status and control signals
		LOCKED            : out    std_logic
	);
	end component;

	-- syscon
	signal sys_reset, sys_resetn,sys_clk, clock_locked : std_logic ;
	signal clk_100Mhz, clk_120Mhz, clk_24Mhz, clk_50Mhz, clk_50Mhz_ext : std_logic ;

	-- wishbone intercon signals
	signal intercon_wrapper_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_strobe :  std_logic;
	signal intercon_wrapper_wbm_write :  std_logic;
	signal intercon_wrapper_wbm_ack :  std_logic;
	signal intercon_wrapper_wbm_cycle :  std_logic;

	signal intercon_leds0_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_leds0_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_leds0_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_leds0_wbm_strobe :  std_logic;
	signal intercon_leds0_wbm_write :  std_logic;
	signal intercon_leds0_wbm_ack :  std_logic;
	signal intercon_leds0_wbm_cycle :  std_logic;
	
	signal intercon_sw0_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_sw0_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_sw0_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_sw0_wbm_strobe :  std_logic;
	signal intercon_sw0_wbm_write :  std_logic;
	signal intercon_sw0_wbm_ack :  std_logic;
	signal intercon_sw0_wbm_cycle :  std_logic;
	
	signal led0_cs, sw0_cs: std_logic ;
	

-- counter signals
	signal divider_output : std_logic_vector(31 downto 0);
	signal onehz_signal : std_logic ;
	constant DIVIDER : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(100_000_000, 32));
-- registers signals
	signal output_to_logic, input_from_logic : std_logic_vector(15 downto 0) ;

-- counter signals
	signal counter_output : std_logic_vector(7 downto 0);
	signal counter_enable, counter_reset : std_logic ;
	
begin

sys_reset <= NOT PB(0); 
sys_resetn <= NOT sys_reset ; -- for preipherals with active low reset

pll0 : clock_gen
  port map
   (-- Clock in ports
    CLK_IN1 => OSC_FPGA,
    -- Clock out ports
    CLK_OUT1 => clk_100Mhz,
    CLK_OUT2 => clk_120Mhz,
	 CLK_OUT3 => clk_24Mhz,
    -- Status and control signals
    LOCKED => clock_locked);

sys_clk <= clk_100Mhz;

process(sys_clk, sys_reset)
begin
	if sys_reset='1' then
		divider_output <= DIVIDER ;
	elsif sys_clk'event and sys_clk = '1' then
		if divider_output = 0 then
			divider_output <= DIVIDER ;
		else
			divider_output <= divider_output - 1 ;
		end if ;
	end if ;
end process ;
onehz_signal <= '1' when divider_output = 0 else
					'0' ;


mem_interface0 : spi_wishbone_wrapper
		port map(
			-- Global Signals
			gls_reset => sys_reset,
			gls_clk   => sys_clk,
			
			-- SPI signals
			mosi => SYS_SPI_MOSI,
			miso => SYS_SPI_MISO,
			sck => SYS_SPI_SCK,
			ss => RP_SPI_CE0N,
			
			  -- Wishbone interface signals
			wbm_address    => intercon_wrapper_wbm_address,  -- Address bus
			wbm_readdata   => intercon_wrapper_wbm_readdata,  -- Data bus for read access
			wbm_writedata 	=> intercon_wrapper_wbm_writedata,  -- Data bus for write access
			wbm_strobe     => intercon_wrapper_wbm_strobe,                      -- Data Strobe
			wbm_write      => intercon_wrapper_wbm_write,                      -- Write access
			wbm_ack        => intercon_wrapper_wbm_ack,                      -- acknowledge
			wbm_cycle      => intercon_wrapper_wbm_cycle                       -- bus cycle in progress
			);



-- Intercon -----------------------------------------------------------
-- will be generated automatically in the future

led0_cs <= '1' when intercon_wrapper_wbm_address(15 downto 0) = "0000000000000000" else
				'0' ;
sw0_cs <= '1' when intercon_wrapper_wbm_address(15 downto 0) = "0000000000000001" else
				'0' ;


intercon_leds0_wbm_address <= intercon_wrapper_wbm_address ;
intercon_leds0_wbm_writedata <= intercon_wrapper_wbm_writedata ;
intercon_leds0_wbm_write <= intercon_wrapper_wbm_write and led0_cs ;
intercon_leds0_wbm_strobe <= intercon_wrapper_wbm_strobe and led0_cs ;
intercon_leds0_wbm_cycle <= intercon_wrapper_wbm_cycle and led0_cs ;

intercon_sw0_wbm_address <= intercon_wrapper_wbm_address ;
intercon_sw0_wbm_writedata <= intercon_wrapper_wbm_writedata ;
intercon_sw0_wbm_write <= intercon_wrapper_wbm_write and sw0_cs ;
intercon_sw0_wbm_strobe <= intercon_wrapper_wbm_strobe and sw0_cs ;
intercon_sw0_wbm_cycle <= intercon_wrapper_wbm_cycle and sw0_cs ;			
							


intercon_wrapper_wbm_readdata	<= intercon_leds0_wbm_readdata when led0_cs = '1' else
											intercon_sw0_wbm_readdata when sw0_cs = '1' else
											intercon_wrapper_wbm_address ;
											
intercon_wrapper_wbm_ack	<= intercon_leds0_wbm_ack when led0_cs = '1' else
										intercon_sw0_wbm_ack when sw0_cs = '1' else
										'0' ;
									      
-----------------------------------------------------------------------

leds0 : logi_virtual_led
	 port map
	 (
		  -- Syscon signals
		  gls_reset   => sys_reset ,
		  gls_clk     => sys_clk ,
		  -- Wishbone signals
		  wbs_add      =>  intercon_leds0_wbm_address ,
		  wbs_writedata => intercon_leds0_wbm_writedata,
		  wbs_readdata  => intercon_leds0_wbm_readdata,
		  wbs_strobe    => intercon_leds0_wbm_strobe,
		  wbs_cycle     => intercon_leds0_wbm_cycle,
		  wbs_write     => intercon_leds0_wbm_write,
		  wbs_ack       => intercon_leds0_wbm_ack,
		 
		  led => input_from_logic
	 );
	 
	 sw0 : logi_virtual_sw
	 port map
	 (
		  -- Syscon signals
		  gls_reset   => sys_reset ,
		  gls_clk     => sys_clk ,
		  -- Wishbone signals
		  wbs_add      =>  intercon_sw0_wbm_address ,
		  wbs_writedata => intercon_sw0_wbm_writedata,
		  wbs_readdata  => intercon_sw0_wbm_readdata,
		  wbs_strobe    => intercon_sw0_wbm_strobe,
		  wbs_cycle     => intercon_sw0_wbm_cycle,
		  wbs_write     => intercon_sw0_wbm_write,
		  wbs_ack       => intercon_sw0_wbm_ack,
		 
		  sw => output_to_logic
	 );
	 
	 
	 -- Device under test
	 counter_enable  <= output_to_logic(0);
	 counter_reset  <= output_to_logic(1);
	 input_from_logic(7 downto 0) <= counter_output;
	 input_from_logic(9 downto 8) <= SW;
	 input_from_logic(10) <= PB(1);
	 
	 process(sys_clk, sys_reset)
	 begin
		if sys_reset = '1' then
			counter_output <= (others => '0');
		elsif sys_clk'event and sys_clk = '1' then
			if counter_reset = '1' then
				counter_output <= (others => '0');
			elsif counter_enable = '1' and onehz_signal = '1' then
				counter_output <= counter_output + 1;
			end if ;
		end if ;
	 end process ;
	
	LED <=  counter_output(1 downto 0);

end Behavioral;

