-- Listing 3.15
--******************************************************************
-- Port to Mark1 Notes: 
-- * changed sw(7:0) to sw(3:0)  MJ
--*******************************************************************/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sm_add_test is
   port(
      clk: in std_logic;
      n_btn: in std_logic_vector(1 downto 0);
      sw: in std_logic_vector(3 downto 0);
      an: out std_logic_vector(3 downto 0);
      sseg: out std_logic_vector(7 downto 0)
   );
end sm_add_test;

architecture arch of sm_add_test is
	signal btn: std_logic_vector(1 downto 0);	--invert the btn signals
	--signal n_an: std_logic_vector(3 downto 0);
	
   signal sum, mout, oct: std_logic_vector(3 downto 0);
   signal led3, led2, led1, led0: std_logic_vector(7 downto 0);
begin
	btn <= not(n_btn);
	--an <= not(n_an);
	
   -- instantiate adder
   sm_adder_unit: entity work.sign_mag_add
      generic map(N=>4)
      --!port map(a=>sw(3 downto 0), b=>sw(7 downto 4),
		port map(a=>sw(3 downto 0), b=>sw(3 downto 0),
               sum=>sum);

   -- 3-to-1 mux to select a number to display
   with btn select
      mout <= sw(3 downto 0) when "00",  -- a
              --!sw(7 downto 4) when "01",  -- b
				  sw(3 downto 0) when "01",  -- b
              sum when others;           -- sum

   -- magnitude displayed on rightmost 7-seg LED
   oct <= '0' & mout(2 downto 0);
   sseg_unit: entity work.hex_to_sseg
      port map(
			hex=>oct, 
			dp=>'0', 
			sseg=>led0
		);
		
--   -- sign displayed on 2nd 7-seg LED
--   led1 <= "11111110" when mout(3)='1' else -- middle bar
--           "11111111";                      -- blank
--   -- other two 7-seg LEDs blank
--   led2 <= "11111111";
--   led3 <= "11111111";

	-- sign displayed on 2nd 7-seg LED
	led1 <= "00000001" when mout(3)='1' else -- middle bar
			  "00000000";                      -- blank
			  
	-- other two 7-seg LEDs blank
	led2 <= "00000000";
	led3 <= "00000000";

   -- instantiate display multiplexer
   disp_unit: entity work.disp_mux
      port map(
         clk=>clk, reset=>'0',
         in0=>led0, 
			in1=>led1, 
			in2=>led2, 
			in3=>led3,
         --an=>n_an, 
			an=>an,
			sseg=>sseg
		);
			
end arch;