----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:23:48 05/28/2013 
-- Design Name: 
-- Module Name:    nes_test - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity nes_test is
	port(
			clk : in std_logic;
			reset_n : in std_logic;
			nes1_dat : in std_logic;
			nes2_dat : in std_logic;
			nes_lat : out std_logic;
			nes_clk : out std_logic;	
			led: out std_logic_vector(1 downto 0)
			);
end nes_test;

architecture arch of nes_test is
	signal nes_clk_buf, nes_lat_buf:std_logic;
	signal nes1_data_out, nes2_data_out: std_logic_vector(7 downto 0);
	signal reset: std_logic;

begin
	reset <= not(reset_n);

	nes_lat <= nes_lat_buf;
	nes_clk <= nes_clk_buf;

	led(0) <= nes1_data_out(0) or nes1_data_out(1) or nes1_data_out(2) or nes1_data_out(3) 
		or nes1_data_out(4) or nes1_data_out(5) or nes1_data_out(6) or nes1_data_out(7) or 
		nes2_data_out(0) or nes2_data_out(1) or nes2_data_out(2) or nes2_data_out(3) 
		or nes2_data_out(4) or nes2_data_out(5) or nes2_data_out(6) or nes2_data_out(7);

	led(1) <= nes_lat_buf;
	
	nes1_unit: entity work.nes_ctl(arch)
		generic map( N=>17)--17 bit overflow 131k
		port map(
				clk=>clk,
				reset=>reset,
				--nes_dat=>nes1_dat,
				nes_dat=>nes1_dat,
				nes_lat=>nes_lat_buf,
				nes_clk=>nes_clk_buf,	
				nes_data_out=>nes1_data_out		
		);
		
		nes2_unit: entity work.nes_ctl(arch)
		generic map( N=>17)--17 bit overflow 131k
		port map(
				clk=>clk,
				reset=>reset,
				nes_dat=>nes2_dat,
				nes_lat=>open,
				nes_clk=>open,	
				nes_data_out=>nes2_data_out		
		);



end arch;

