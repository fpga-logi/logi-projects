-- Listing 4.14
--******************************************************************
-- Port to Mark1 Notes: 
-- * Changed SW to 3:0 instead of 7:0
-- To Do: Will add btn function to switch between expected sw(7:4) = sw(3:0);
-- To Do: btn function not working properly
--******************************************************************/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity disp_mux_test is
   port(
		led: out std_logic_vector(7 downto 0);
      clk: in std_logic;
      n_btn: in std_logic_vector(3 downto 0);
      sw: in std_logic_vector(3 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end disp_mux_test;

architecture arch of disp_mux_test is
	signal n_an: std_logic_vector(3 downto 0);
	signal btn: std_logic_vector(3 downto 0);
   signal d3_reg, d2_reg: std_logic_vector(7 downto 0);
   signal d1_reg, d0_reg: std_logic_vector(7 downto 0);

begin

   disp_unit: entity work.disp_mux
      port map(
				clk=>clk, reset=>'0',
				in3=>d3_reg, 
				in2=>d2_reg, 
				in1=>d1_reg,
				in0=>d0_reg, 
				an=>an, 
				sseg=>sseg
			);
		
	--an <= not(n_an);	--invert the an signals to support existing book code.		
	btn <= not(n_btn);		
	led(3 downto 0) <= btn;
	led(7 downto 4) <= n_btn;
	
   -- registers for 4 led patterns
   process (clk)
   begin
      if (clk'event and clk='1') then
         if (btn(3)='1') then
            --!d3_reg <= sw;
				d3_reg <= "0000" & sw;
         end if;
         if (btn(2)='1') then
            d2_reg <= "0000" & sw;
         end if;
         if (btn(1)='1') then
            d1_reg <= "0000" & sw;
         end if;
         if (btn(0)='1') then
            d0_reg <= "0000" & sw;
         end if;
      end if;
   end process;
	
end arch;