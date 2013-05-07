----------------------------------------------------------------------------------
-- Engineer: Mike Field (hamster@snap.net.nz)
-- 
-- Create Date:    20:30:34 02/15/2012 
-- Module Name:    sram_memtest - Behavioral 
-- Description:    Memory interface for SRAM tester for the Papilio Plus board.
-- 
--
-- Requirements: 
--   - All "mem_*" signals must have IOB=TRUE set in the Implementation Constraints file.
--   - Maximum clock is 100MHz 
--   - The memtest_clk component must generate three signals
--       - clk_mem - System clock
--       - clk_we  - this should occur late enough to raise "mem_we" just before mem_clk, but
--                   meeting the length requirments of the Write Enable pulse.
--       - clk_wen - This is used to lower the write enable pulse, and latch the data bus. This
--                   should occur as early in the cycle as possible. It needs to occur soon enough
--                   after clk_mem to capture the data before outputs change, but late enough to 
--                   ensure that the address and data lines are stable when the Write enable pulse
--                   occurs.
--  At 100MHz the phase angle for clk_we is 50 degrees (for 1.5ns after clk_mem) and 342 degrees for 
--  clk_we (0.5ns ahead of clk_mem).
--
-- The conficting timing requirement is the delay required for the flip-flop holding the signal for mem_we
-- to propogate through the FPGA fabric the ODDR2 output.
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity sram_memtest is
   GENERIC (
      addr_width : natural := 18;
      data_width : natural := 16
   );
   PORT (
      clk_mem,clk_wen, clk_we    : IN    STD_LOGIC;
      mem_addr : OUT   STD_LOGIC_VECTOR(addr_width-1 downto 0);
      mem_data : INOUT STD_LOGIC_VECTOR(data_width-1 downto 0);
      mem_nCE  : OUT   STD_LOGIC;
      mem_nWE  : OUT   STD_LOGIC;
      mem_nOE  : OUT   STD_LOGIC;
      mem_nBE  : OUT   STD_LOGIC;
      memcheck_done : OUT STD_LOGIC;
      memcheck_failed : OUT STD_LOGIC
   );   
end sram_memtest;

architecture Behavioral of sram_memtest is

   COMPONENT test_generator
   GENERIC (
      data_width : NATURAL := 16;
      addr_width : NATURAL := 18
   );
   PORT(
      clk          : IN std_logic;          
      address      : OUT std_logic_vector(addr_width-1 downto 0);
      data         : OUT std_logic_vector(data_width-1 downto 0);
      readback     : OUT std_logic;
      test_cycle   : OUT std_logic;
      completed    : OUT std_logic
      );
   END COMPONENT;

   signal test_addr    : STD_LOGIC_VECTOR(addr_width-1 downto 0) := (others => '0');
   signal test_data    : STD_LOGIC_VECTOR(data_width-1 downto 0) := (others => '0');
   signal test_do_read : STD_LOGIC;
   signal test_is_test_cycle : STD_LOGIC;
   
   signal out_write_enable     : STD_LOGIC := '1';

   signal hold_data            : STD_LOGIC_VECTOR(data_width-1 downto 0) := (others => '0');
   signal check_data           : STD_LOGIC_VECTOR(data_width-1 downto 0) := (others => '0');
   signal check_data_against   : STD_LOGIC_VECTOR(data_width-1 downto 0) := (others => '0');
   signal mem_data_reg         : STD_LOGIC_VECTOR(data_width-1 downto 0) := (others => '0');

   signal hiz                  : STD_LOGIC := '0';
   signal running_test_cycle   : STD_LOGIC := '0';
   signal completed_flag       : STD_LOGIC;
   
   signal failed_flag          : std_logic := '0';

begin

   Inst_test_generator: test_generator 
	GENERIC MAP( data_width => data_width,
      addr_width => addr_width)
	PORT MAP(
      clk       => clk_mem,
      address   => test_addr,
      data      => test_data,
      readback  => test_do_read,
      test_cycle => test_is_test_cycle,
      completed => completed_flag
   );
    
   -- Global output signals
   mem_nCE <= '0';
   mem_nBE <= '0';
   memcheck_done   <= completed_flag;
   memcheck_failed <= failed_flag;
   
   -- DDR output to generate the Write Enable (WE) pulse
   ODDR2_nWE : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE",    -- Sets output alignment to "NONE", "C0", "C1" 
      INIT          => '1',     -- Sets initial state of the Q output to '0' or '1'
      SRTYPE        => "ASYNC") -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q  => mem_nWE,              -- 1-bit output data
      C0 => clk_we,              -- 1-bit clock input
      C1 => clk_wen,             -- 1-bit clock input
      CE => '1',                  -- 1-bit clock enable input
      D0 => '1', -- 1-bit data input (associated with C0)
      D1 => out_write_enable, -- 1-bit data input (associated with C1)
      R  => '0',                   -- 1-bit reset input
      S  => '0'                   -- 1-bit set input
   );

   tristate_proc: process(hiz,mem_data_reg)
   begin
      if hiz = '0' then 
         mem_data <= mem_data_reg;
      else
         mem_data <= "ZZZZZZZZZZZZZZZZ";
      end if;
   end process;

   -- Constantly latch the memory values
   process(clk_wen)
   begin
      if rising_edge(clk_wen) then
         check_data <= mem_data;
      end if;
   end process;
   
   process(clk_mem)
   begin
      if rising_edge(clk_mem) then
         if running_test_cycle = '1' then
            if check_data_against /= check_data then
               failed_flag <= '1';
            end if;
         end if;
         
         mem_addr         <= test_addr;
         if test_do_read = '1' then
            -- read cycle
            mem_nOE          <= '0';
            out_write_enable <= '1';
            hiz              <= '1';
         else
            -- write
            mem_nOE          <= '1';
            out_write_enable <= '0';
            hiz              <= '0';
            mem_data_reg     <= test_data;
         end if;

         check_data_against <= hold_data;
         hold_data          <= test_data;         
         running_test_cycle <= test_Is_test_cycle;
      end if;
   end process;
end Behavioral;
