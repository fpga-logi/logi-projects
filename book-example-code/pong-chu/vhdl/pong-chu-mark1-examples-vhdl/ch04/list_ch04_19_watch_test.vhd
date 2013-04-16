--Listing 4.19
library ieee;
use ieee.std_logic_1164.all;
entity stop_watch_test is
   port(
      clk: in std_logic;
      btn: in std_logic_vector(3 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end stop_watch_test;

architecture arch of stop_watch_test is
   signal d2, d1, d0: std_logic_vector(3 downto 0);
begin
   disp_unit: entity work.disp_hex_mux
      port map(
         clk=>clk, reset=>'0',
         hex3=>"0000", hex2=>d2,
         hex1=>d1, hex0=>d0,
         dp_in=>"1101", an=>an, sseg=>sseg);

  watch_unit: entity work.stop_watch(cascade_arch)
     port map(
        clk=>clk, go=>btn(1), clr=>btn(0),
        d2 =>d2, d1=>d1, d0=>d0 );
end arch;