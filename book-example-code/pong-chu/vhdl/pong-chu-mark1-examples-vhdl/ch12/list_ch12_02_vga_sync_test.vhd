-- Listing 12.2
library ieee;
use ieee.std_logic_1164.all;
entity vga_test is
   port (
      clk, reset: in std_logic;
      sw: in std_logic_vector(2 downto 0);
      hsync, vsync: out  std_logic;
      rgb: out std_logic_vector(2 downto 0)
   );
end vga_test;

architecture arch of vga_test is
   signal rgb_reg: std_logic_vector(2 downto 0);
   signal video_on: std_logic;
begin
   -- instantiate VGA sync circuit
   vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset, hsync=>hsync,
               vsync=>vsync, video_on=>video_on,
               p_tick=>open, pixel_x=>open, pixel_y=>open);
   -- rgb buffer
   process (clk,reset)
   begin
      if reset='1' then
         rgb_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         rgb_reg <= sw;
      end if;
   end process;
   rgb <= rgb_reg when video_on='1' else "000";
end arch;