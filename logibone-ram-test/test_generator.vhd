----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Description: 
--   Generates 16 test patterns for testing SDRAM
--
--   Test partterns are:
--    - fill with zeros, then verify
--    - fill with ones, then verify
--    - fill with even bits, then verify
--    - fill with ddd bits, then verify
--    - fill with the low 16 bits of the address, then verify
--    - fill with the high 16 bits of the address, then verify
--    - fill with odd bits on odd addresses, even bits on even addresses, then verify
--    - fill with even bits on odd addresses, odd bits on even addresses, then verify
--    - Word at a time with zeros, verifying immediately after write
--    - Word at a time with ones, verifying immediately after write
--    - Word at a time with even bits, verifying immediately after write
--    - Word at a time with odd bits, verifying immediately after write
--    - Word at a time with the low 16 bits of the address, verifying immediately after write
--    - Word at a time with the high 16 bits of the address, verifying immediately after write
--    - Word at a time with odd bits on odd addresses, even bits on even addresses, verifying immediately after write
--    - Word at a time with even bits on odd addresses, odd bits on even addresses, verifying immediately after write
--
--
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity test_generator is
   Generic (addr_width : natural := 17;
            data_width : natural := 16);
    Port ( clk       : in  STD_LOGIC;
           address   : out  STD_LOGIC_VECTOR (addr_width-1 downto 0);
           data      : out  STD_LOGIC_VECTOR (data_width-1 downto 0);
           readback   : out  STD_LOGIC;
           test_cycle : out  STD_LOGIC;
           completed : out  STD_LOGIC
           );
end test_generator;

architecture Behavioral of test_generator is
   constant final_address : STD_LOGIC_VECTOR(addr_width-1 downto 0) := (others => '1');
   constant first_address : STD_LOGIC_VECTOR(addr_width-1 downto 0) := (others => '0');

   signal completed_flag  : std_logic := '0';

   signal addr_counter    : STD_LOGIC_VECTOR(addr_width-1 downto 0) := first_address;
   signal pattern_counter : STD_LOGIC_VECTOR(2 downto 0)            := (others => '0');
   signal interleave      : std_logic := '0';
   signal reset_counter   : STD_LOGIC_VECTOR(24 downto 0) := (others => '1');
   
   signal next_data    : STD_LOGIC_VECTOR(data_width-1 downto 0);
   signal next_do_read : STD_LOGIC := '0';
   
   constant zeros      : std_logic_vector(31 downto 0) := x"00000000";
   constant odd_bits   : std_logic_vector(31 downto 0) := x"AAAAAAAA";
   constant even_bits  : std_logic_vector(31 downto 0) := x"55555555";
   constant ones       : std_logic_vector(31 downto 0) := x"FFFFFFFF";

begin
   completed <= completed_flag;

   next_data <= zeros(data_width-1 downto 0)                      when pattern_counter = "000"
                else ones(data_width-1 downto 0)                  when pattern_counter = "001"
                else even_bits(data_width-1 downto 0)             when pattern_counter = "010"
                else odd_bits(data_width-1 downto 0)              when pattern_counter = "011"
                --else addr_counter(data_width-1 downto 0)          when pattern_counter = "100"
                --else addr_counter(addr_width-1 downto (addr_width - data_width)) when pattern_counter = "101"
                else even_bits(data_width-1 downto 0)             when pattern_counter = "110" and addr_counter(0) <= '0'
                else odd_bits(data_width-1 downto 0)              when pattern_counter = "110" and addr_counter(0) <= '1'
                else odd_bits(data_width-1 downto 0)              when pattern_counter = "111" and addr_counter(0) <= '0'
                else even_bits(data_width-1 downto 0)             when pattern_counter = "111" and addr_counter(0) <= '1'
                else zeros(data_width-1 downto 0);
                
   process(clk)
   begin
      if rising_edge(clk) then
         if reset_counter = 0 then
            address    <= addr_counter;
            data       <= next_data;
            readback   <= next_do_read;
            test_cycle <= next_do_read;
            
            if completed_flag = '0' then
               if interleave = '0' then
                  -- write all addresses, read all addresses, then all patterns
                  if addr_counter = final_address then
                     if next_do_read = '0' then
                        next_do_read <= '1';
                     else
                        next_do_read <= '0';
                        if pattern_counter  = "111" then
                           interleave <= '1';
                        end if;
                        pattern_counter <= pattern_counter + 1;
                     end if;
                     addr_counter <= first_address;
                  else
                     addr_counter <= addr_counter + 1;
                  end if;
               else
                  -- write then read, all addresses, then all patterns
                  if next_do_read = '0' then
                     next_do_read <= '1';
                  else
                     next_do_read <= '0';
                     if addr_counter = final_address  then
                        if pattern_counter = "111" then
                           completed_flag <= '1';
                        end if;
                        pattern_counter <= pattern_counter + 1;
                        addr_counter <= first_address;
                     else
                        addr_counter <= addr_counter + 1;
                     end if;
                  end if;
               end if;
            end if;
         else
            reset_counter <= reset_counter - 1;
            address       <= (others => '0');
            data            <= (others => '0');
            addr_counter  <= first_address;
            readback      <= '0';
            test_cycle    <= '0';
         end if;
      end if;

   end process;
end Behavioral;