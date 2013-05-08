----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:14:22 06/21/2012 
-- Design Name: 
-- Module Name:    spartcam_beaglebone - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

library work ;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity logibone_ram_test is
port( OSC_FPGA : in std_logic;
		PB : in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(1 downto 0);	
		
		--sram interface
		SRAM_CSN, SRAM_WEN, SRAM_OEN, SRAM_BLEN, SRAM_BHEN : out std_logic ;
		SRAM_ADD : out std_logic_vector(18 downto 0);
		SRAM_DATA : inout std_logic_vector(15 downto 0)
);
end logibone_ram_test;

architecture Behavioral of logibone_ram_test is

component clock_gen
port
 (-- Clock in ports
  CLK_IN1           : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic;
  CLK_OUT2          : out    std_logic;
  CLK_OUT3          : out    std_logic;
  -- Status and control signals
  LOCKED            : out    std_logic
 );
end component;

component sram_memtest is
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
end component;


	
	signal clk_mem, clk_wen, clk_we : std_logic ;
	signal resetn , sys_resetn : std_logic ;
	signal test_done, test_failed : std_logic ;
	signal counter_output : std_logic_vector(31 downto 0);
	signal ben : std_logic ;
	
begin
	
	
	mem_clock0 : clock_gen
  port map
   (-- Clock in ports
    CLK_IN1 => OSC_FPGA,
    -- Clock out ports
    CLK_OUT1 => clk_mem,
    CLK_OUT2 => clk_we, -- 342° phase
    CLK_OUT3 => clk_wen, -- 50° phase
    -- Status and control signals
    LOCKED => open);


LED(0) <= test_done;
LED(1) <= test_failed;


test_gen : sram_memtest 
   GENERIC MAP(
      addr_width => 12,
      data_width => 16)
   PORT MAP(
      clk_mem     => clk_mem,
		clk_we     => clk_we,
		clk_wen     => clk_wen,
      mem_addr => SRAM_ADD(11 downto 0),
      mem_data => SRAM_DATA,
      mem_nCE  => SRAM_CSN,
      mem_nWE  => SRAM_WEN,
      mem_nOE  => SRAM_OEN,
      mem_nBE  => ben,
      memcheck_done => test_done,
      memcheck_failed => test_failed
   );   
SRAM_ADD(18 downto 12) <= (others => '0') ;
SRAM_BLEN <= '0';
SRAM_BHEN <= '0' ;

end Behavioral;

