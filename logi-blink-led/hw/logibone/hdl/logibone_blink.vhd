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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL

library work ;
use work.control_pack.all ;
use work.control_pack.all ;
use work.control_pack.all ;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity logibone_blink is
port( OSC_FPGA : in std_logic;

		-- i2c pins 
		ARD_SCL, ARD_SDA : inout std_logic ;
		--onboard
		LED : out std_logic_vector(1 downto 0)
);
end logibone_blink;

architecture Behavioral of logibone_blink is
	
	-- Led counter
	signal counter_output : std_logic_vector(31 downto 0);
	
begin
	
		
	ARD_SCL <= 'Z' ;
	ARD_SDA <= 'Z' ;
	
	process(OSC_FPGA)
	begin
		if OSC_FPGA'event and OSC_FPGA = '1' then
			counter_output <= counter_output + 1 ;
		end if;
	end process ;
	LED(0) <= counter_output(24);
	--LED(1) <= counter_output(23);
	
	
	
	beat0 : heart_beat
	generic map(clk_period_ns => 20, 
					beat_period_ns => 900_000_000,
					beat_length_ns => 100_000_000)
	port map( gls_clk => OSC_FPGA,
				gls_reset => '0',
				beat_out => LED(1)
	);
	 LED <= (others => 'Z') ;
	
end Behavioral;

