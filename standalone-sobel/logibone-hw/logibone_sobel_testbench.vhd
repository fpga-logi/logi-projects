--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:15:42 01/11/2013
-- Design Name:   
-- Module Name:   /home/jpiat/development/FPGA/fpga-cam/platform/logibone/logibone_sobel/logibone_sobel_testbench.vhd
-- Project Name:  logibone_sobel
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: logibone_sobel
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
USE ieee.numeric_std.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY logibone_sobel_testbench IS
END logibone_sobel_testbench;
 
ARCHITECTURE behavior OF logibone_sobel_testbench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT logibone_sobel
    PORT(
         OSC_FPGA : IN  std_logic;
         PB : IN  std_logic_vector(1 downto 0);
         LED : OUT  std_logic_vector(1 downto 0);
         GPMC_CSN : IN  std_logic_vector(2 downto 0);
         GPMC_WEN : IN  std_logic;
         GPMC_OEN : IN  std_logic;
         GPMC_ADVN : IN  std_logic;
         GPMC_CLK : IN  std_logic;
         GPMC_BE0N : IN  std_logic;
         GPMC_BE1N : IN  std_logic;
         GPMC_AD : INOUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal OSC_FPGA : std_logic := '0';
   signal PB : std_logic_vector(1 downto 0) := (others => '0');
   signal GPMC_CSN : std_logic_vector(2 downto 0) := (others => '0');
   signal GPMC_WEN : std_logic := '0';
   signal GPMC_OEN : std_logic := '0';
   signal GPMC_ADVN : std_logic := '0';
   signal GPMC_CLK : std_logic := '0';
   signal GPMC_BE0N : std_logic := '0';
   signal GPMC_BE1N : std_logic := '0';

	--BiDirs
   signal GPMC_AD : std_logic_vector(15 downto 0);

 	--Outputs
   signal LED : std_logic_vector(1 downto 0);

   -- Clock period definitions
   constant OSC_FPGA_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: logibone_sobel PORT MAP (
          OSC_FPGA => OSC_FPGA,
          PB => PB,
          LED => LED,
          GPMC_CSN => GPMC_CSN,
          GPMC_WEN => GPMC_WEN,
          GPMC_OEN => GPMC_OEN,
          GPMC_ADVN => GPMC_ADVN,
          GPMC_CLK => GPMC_CLK,
          GPMC_BE0N => GPMC_BE0N,
          GPMC_BE1N => GPMC_BE1N,
          GPMC_AD => GPMC_AD
        );

   -- Clock process definitions
   GPMC_CLK_process :process
   begin
		OSC_FPGA <= '0';
		wait for OSC_FPGA_period/2;
		OSC_FPGA <= '1';
		wait for OSC_FPGA_period/2;
   end process;
 

   stim_proc: process
	variable count_loops : integer := 0 ;
   begin		
       PB(0) <= '0' ;
		GPMC_AD <=  (others => 'Z') ;
		GPMC_CSN(1) <= '1' ;
		GPMC_ADVN <= '1' ;
		GPMC_OEN <= '1' ;
		GPMC_WEN <= '1' ;
      wait for 100 ns;	
		 PB(0) <= '1' ;
		wait for OSC_FPGA_period*2000;	
      wait for OSC_FPGA_period*10;
		while count_loops < (320 * 240) loop
			--writing to fifo
			GPMC_AD <= X"0000" ;
			GPMC_CSN(1) <= '0' ;
			GPMC_ADVN <= '0' ;
			GPMC_OEN <= '1' ;
			GPMC_WEN <= '1' ;
			wait for OSC_FPGA_period;
			GPMC_AD <= (others => 'Z') ;
			GPMC_CSN(1) <= '0' ;
			GPMC_ADVN <= '1' ;
			GPMC_OEN <= '1' ;
			GPMC_WEN <= '1' ;
			wait for OSC_FPGA_period;
			GPMC_AD <= std_logic_vector(to_unsigned(count_loops, 16)) ;
			GPMC_CSN(1) <= '0' ;
			GPMC_ADVN <= '1' ;
			GPMC_OEN <= '1' ;
			GPMC_WEN <= '0' ;
			wait for OSC_FPGA_period*2;
			GPMC_AD <= (others => 'Z') ;
			GPMC_CSN(1) <= '1' ;
			GPMC_ADVN <= '1' ;
			GPMC_OEN <= '1' ;
			GPMC_WEN <= '1' ;
			wait for OSC_FPGA_period*10;
			count_loops := count_loops + 1 ;
		end loop ;
      -- insert stimulus here 

      wait;
   end process;


END;
