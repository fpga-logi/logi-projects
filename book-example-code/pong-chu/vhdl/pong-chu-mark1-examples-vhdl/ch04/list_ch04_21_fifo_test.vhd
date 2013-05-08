-- Listing 4.21
library ieee;
use ieee.std_logic_1164.all;
entity fifo_test is
   port(
      clk, reset: in std_logic;
      btn: std_logic_vector(1 downto 0);
      sw: std_logic_vector(2 downto 0);
      led: out std_logic_vector(7 downto 0)
   );
end fifo_test;

architecture arch of fifo_test is
   signal db_btn: std_logic_vector(1 downto 0);
begin
   -- debounce circuit for btn(0)
   btn_db_unit0: entity work.debounce(fsmd_arch)
      port map(clk=>clk, reset=>reset, sw=>btn(0),
               db_level=>open, db_tick=>db_btn(0));
   -- debounce circuit for btn(1)
   btn_db_unit1: entity work.debounce(fsmd_arch)
      port map(clk=>clk, reset=>reset, sw=>btn(1),
               db_level=>open, db_tick=>db_btn(1));
   -- instantiate a 2^2-by-3 fifo)
   fifo_unit: entity work.fifo(arch)
      generic map(B=>3, W=>2)
      port map(clk=>clk, reset=>reset,
               rd=>db_btn(0), wr=>db_btn(1),
               w_data=>sw, r_data=>led(2 downto 0),
               full=>led(7), empty=>led(6));
   -- disable unused leds
   led(5 downto 3)<=(others=>'0');
 end arch;