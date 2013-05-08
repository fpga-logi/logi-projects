-- Listing 9.5
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity mouse_led is
   port (
      clk, reset: in  std_logic;
      ps2d, ps2c: inout std_logic;
      led: out std_logic_vector(7 downto 0)
   );
end mouse_led;

architecture arch of mouse_led is
   signal p_reg, p_next: unsigned(9 downto 0);
   signal xm: std_logic_vector(8 downto 0);
   signal btnm: std_logic_vector(2 downto 0);
   signal m_done_tick: std_logic;

begin
   -- instantiation
   mouse_unit: entity work.mouse(arch)
      port map(clk=>clk, reset=>reset,
               ps2d=>ps2d, ps2c=>ps2c,
               xm=>xm, ym=>open, btnm=>btnm,
               m_done_tick=>m_done_tick);
   -- register
   process (clk, reset)
   begin
      if reset='1' then
         p_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         p_reg <= p_next;
      end if;
   end process;
   -- counter
   p_next <= p_reg when m_done_tick='0' else
             "0000000000" when btnm(0)='1' else --left button
             "1111111111" when btnm(1)='1' else --right button
             p_reg + unsigned(xm(8) & xm);

   with p_reg(9 downto 7) select
      led <= "10000000" when "000",
             "01000000" when "001",
             "00100000" when "010",
             "00010000" when "011",
             "00001000" when "100",
             "00000100" when "101",
             "00000010" when "110",
             "00000001" when others;
end arch;