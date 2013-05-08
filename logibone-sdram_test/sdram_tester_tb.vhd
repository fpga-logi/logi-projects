--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:00:49 05/08/2013
-- Design Name:   
-- Module Name:   /home/jpiat/development/FPGA/logi-family/logi-projects/logibone-sdram_test/sdram_tester_tb.vhd
-- Project Name:  logibone-sdram_test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: sdram_tester
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY sdram_tester_tb IS
END sdram_tester_tb;
 
ARCHITECTURE behavior OF sdram_tester_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT sdram_tester
    PORT(
         clk : IN  std_logic;
         resetn : IN  std_logic;
         address : OUT  std_logic_vector(23 downto 0);
         data_in : IN  std_logic_vector(31 downto 0);
         data_out : OUT  std_logic_vector(31 downto 0);
         rd : OUT  std_logic;
         wr : OUT  std_logic;
         pending : IN  std_logic;
         data_valid : IN  std_logic;
         test_done : OUT  std_logic;
         test_failed : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal resetn : std_logic := '0';
   signal data_in : std_logic_vector(31 downto 0) := (others => '0');
   signal pending : std_logic := '0';
   signal data_valid : std_logic := '0';

 	--Outputs
   signal address : std_logic_vector(23 downto 0);
   signal data_out : std_logic_vector(31 downto 0);
   signal rd : std_logic;
   signal wr : std_logic;
   signal test_done : std_logic;
   signal test_failed : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: sdram_tester PORT MAP (
          clk => clk,
          resetn => resetn,
          address => address,
          data_in => data_in,
          data_out => data_out,
          rd => rd,
          wr => wr,
          pending => pending,
          data_valid => data_valid,
          test_done => test_done,
          test_failed => test_failed
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
	pending <= '0' ;
	data_valid <= '1' ;
	data_in <= (others => '0');

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		resetn <= '0' ;
      wait for 100 ns;	
		resetn <= '1' ;
      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
