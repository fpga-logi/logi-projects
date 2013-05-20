-- Listing 3.13
--******************************************************************
-- Port to Mark1 Notes: 
-- * changed sw(7:0) to sw(3:0)  MJ
-- * Notes: Search for --! to see the changed sections
--*******************************************************************/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity hex_to_sseg_test is
   port(
      clk: in std_logic;
      sw: in std_logic_vector(3 downto 0);
      an: out std_logic_vector(3 downto 0);
		led: out std_logic_vector(7 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end hex_to_sseg_test;

architecture arch of hex_to_sseg_test is
   signal inc: std_logic_vector(7 downto 0);
   signal led3, led2, led1, led0: std_logic_vector(7 downto 0);
	signal sseg_reg: std_logic_vector(7 downto 0);
begin

--sw is non-inverted logic

--sseg <= "10000001";
--an <= sw;

--led <= "10000001";
--
--an <= "1110";
--sseg <= "10000001";
--with sw select
--       sseg_reg <=
--			"00000001" when "0001",	--a
--			"00000010" when "0010",	--b
--			"00000100" when "0011",	--c
--			"00001000" when "0100",	--d
--			"00010000" when "0101",	--e
--			"00100000" when "0110",	--f
--			"01000000" when "0111",	--g
--			"10000000" when others;	--dp
--
--
--led <= sseg_reg;
--sseg <= sseg_reg;
--
--an <= "1110";




   -- increment input
   --inc <= std_logic_vector(unsigned(sw & sw) + 1);
	inc <= std_logic_vector(unsigned("0000" & sw));
	led <= "0000" & sw;
	

   -- instantiate four instances of hex decoders
   -- instance for 4 LSBs of input
   sseg_unit_0: entity work.hex_to_sseg
      --!port map(hex=>sw(3 downto 0), dp =>'0', sseg=>led0);
		port map(hex=>sw, dp =>'0', sseg=>led0);
   -- instance for 4 MSBs of input
   sseg_unit_1: entity work.hex_to_sseg
      --!port map(hex=>sw(7 downto 4), dp =>'0', sseg=>led1);
		port map(hex=>sw, dp =>'0', sseg=>led1);
   -- instance for 4 LSBs of incremented value
   sseg_unit_2: entity work.hex_to_sseg
      --!port map(hex=>inc(3 downto 0), dp =>'1', sseg=>led2);
		port map(hex=>inc(3 downto 0), dp =>'1', sseg=>led2);
   -- instance for 4 MSBs of incremented value
   sseg_unit_3: entity work.hex_to_sseg
      --!port map(hex=>inc(7 downto 4), dp =>'1', sseg=>led3);
		port map(hex=>inc(3 downto 0), dp =>'1', sseg=>led3);

   -- instantiate 7-seg LED display time-multiplexing module
   disp_unit: entity work.disp_mux
      port map(
         clk=>clk, reset=>'0',
         in0=>led0, in1=>led1, in2=>led2, in3=>led3,
         an=>an, sseg=>sseg);
	
			
			
			
			
end arch;