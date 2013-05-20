-- Listing 3.18
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--******************************************************************
-- Port to Mark1 Notes: 
-- * changed sw(7:0) to sw(3:0)  MJ
-- * Notes: Search for --! to see the changed sections
--*******************************************************************/
entity shifter_test is
   port(
      sw: in std_logic_vector(3 downto 0);
      btn: in std_logic_vector(2 downto 0);
      led: out std_logic_vector(7 downto 0)
   );
end shifter_test;

architecture arch of shifter_test is
begin
   shift_unit: entity work.barrel_shifter(multi_stage_arch)
      --!port map(a=>sw, amt=>btn, y=>led);
		port map(a=> ("0000" & sw) , amt=>btn, y=>led);
end arch;
