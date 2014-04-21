--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:11:38 03/14/2014
-- Design Name:   
-- Module Name:   /home/jpiat/development/FPGA/logi-family/logi-projects/logi-hear/hw/sample162fifo_tb.vhd
-- Project Name:  logi_hear
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: samples162fifo
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
 
ENTITY sample162fifo_tb IS
END sample162fifo_tb;
 
ARCHITECTURE behavior OF sample162fifo_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT samples162fifo
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         frame_info : IN  std_logic_vector(15 downto 0);
         timestamp : IN  std_logic_vector(31 downto 0);
         frame0 : IN  std_logic;
         data : IN  std_logic_vector(23 downto 0);
         data_valid : IN  std_logic;
         fifo_write : OUT  std_logic;
         fifo_data : OUT  std_logic_vector(15 downto 0);
         fifo_full : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal frame_info : std_logic_vector(15 downto 0) := (others => '0');
   signal timestamp : std_logic_vector(31 downto 0) := (others => '0');
   signal frame0 : std_logic := '0';
   signal data : std_logic_vector(23 downto 0) := (others => '0');
   signal data_valid : std_logic := '0';
   signal fifo_full : std_logic := '0';

 	--Outputs
   signal fifo_write : std_logic;
   signal fifo_data : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: samples162fifo PORT MAP (
          clk => clk,
          rst => rst,
          frame_info => frame_info,
          timestamp => timestamp,
          frame0 => frame0,
          data => data,
          data_valid => data_valid,
          fifo_write => fifo_write,
          fifo_data => fifo_data,
          fifo_full => fifo_full
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		rst <= '1' ;
      wait for 100 ns;	
		rst <= '0' ;
      wait for clk_period*10;
		timestamp <= X"DEADBEEF";
		frame_info <= X"ABCD" ;
		frame0 <= '0' ;
		data <= (others => '0');
		data_valid <= '0' ;
		wait for clk_period*10;
		frame0 <= '0' ;
		data <= (others => '0');
		data_valid <= '1' ;
		wait for clk_period*10;
		frame0 <= '0' ;
		data <= (others => '0');
		data_valid <= '0' ;
		wait for clk_period*10;
		frame0 <= '0' ;
		data <= (others => '0');
		data_valid <= '1' ;
		wait for clk_period*10;
		frame0 <= '0' ;
		data <= (others => '0');
		data_valid <= '0' ;
		wait for clk_period*10;
		frame0 <= '1' ;
		data <= X"AAFFBB";
		data_valid <= '1' ;
		wait for clk_period*10;
		frame0 <= '1' ;
		data <= X"AAFFBB";
		data_valid <= '0' ;
		wait for clk_period*10;
		frame0 <= '1' ;
		data <= X"55AADD";
		data_valid <= '1' ;
		wait for clk_period*10;
		frame0 <= '1' ;
		data <= X"55AADD";
		data_valid <= '0' ;
		wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
