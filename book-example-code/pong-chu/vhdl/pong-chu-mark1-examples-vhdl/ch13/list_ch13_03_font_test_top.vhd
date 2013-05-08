-- Listing 13.3
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity font_test_top is
   port(
      clk, reset: in std_logic;
      hsync, vsync: out  std_logic;
      rgb: out std_logic_vector(2 downto 0)
   );
end font_test_top;

architecture arch of font_test_top is
   signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
   signal video_on, pixel_tick: std_logic;
   signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
begin
   -- instantiate VGA sync circuit
   vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset, hsync=>hsync,
               vsync=>vsync, video_on=>video_on,
               pixel_x=>pixel_x, pixel_y=>pixel_y,
               p_tick=>pixel_tick);
   -- instantiate font ROM
   font_gen_unit: entity work.font_test_gen
      port map(clk=>clk, video_on=>video_on,
               pixel_x=>pixel_x, pixel_y=>pixel_y,
               rgb_text=>rgb_next);
   -- rgb buffer
   process (clk)
   begin
      if (clk'event and clk='1') then
         if (pixel_tick='1') then
            rgb_reg <= rgb_next;
         end if;
      end if;
   end process;
   rgb <= rgb_reg;
end arch;