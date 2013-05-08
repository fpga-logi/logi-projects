----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:53:45 05/08/2013 
-- Design Name: 
-- Module Name:    logibone_sdram_test_tb - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity logibone_sdram_test_tb is
end logibone_sdram_test_tb;

architecture Behavioral of logibone_sdram_test_tb is
component sdram_controller is
	  generic (
		 HIGH_BIT: integer := 24;
		 MHZ: integer := 100;
		 REFRESH_CYCLES: integer := 4096;
		 ADDRESS_BITS: integer := 13
	  );
	  PORT (
			clock_100:  in std_logic;
			clock_100_delayed_3ns: in std_logic;
			rst: in std_logic;

		-- Signals to/from the SDRAM chip
		DRAM_ADDR   : OUT   STD_LOGIC_VECTOR (ADDRESS_BITS-1 downto 0);
		DRAM_BA      : OUT   STD_LOGIC_VECTOR (1 downto 0);
		DRAM_CAS_N   : OUT   STD_LOGIC;
		DRAM_CKE      : OUT   STD_LOGIC;
		DRAM_CLK      : OUT   STD_LOGIC;
		DRAM_CS_N   : OUT   STD_LOGIC;
		DRAM_DQ      : INOUT STD_LOGIC_VECTOR(15 downto 0);
		DRAM_DQM      : OUT   STD_LOGIC_VECTOR(1 downto 0);
		DRAM_RAS_N   : OUT   STD_LOGIC;
		DRAM_WE_N    : OUT   STD_LOGIC;

		pending: out std_logic;

		--- Inputs from rest of the system
		address      : IN     STD_LOGIC_VECTOR (HIGH_BIT downto 2);
		req_read      : IN     STD_LOGIC;
		req_write   : IN     STD_LOGIC;
		data_out      : OUT     STD_LOGIC_VECTOR (31 downto 0);
		data_out_valid : OUT     STD_LOGIC;
		data_in      : IN     STD_LOGIC_VECTOR (31 downto 0);
		data_mask    : IN     STD_LOGIC_VECTOR (3 downto 0)
		);
	end component;	

	component sdram_tester is
	generic(ADDR_WIDTH : positive := 24;
			DATA_WIDTH : positive := 32);
	port(
		clk, resetn : in std_logic ;
		address : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
		rd : out std_logic ;
		wr : out std_logic ;
		pending : in std_logic ;
		data_valid : in std_logic;
		
		test_done :out std_logic ;
		test_failed : out std_logic 
		);
	end component;


component mt48lc8m16a2 IS
    GENERIC (
        tAC       : TIME    :=  5.0 ns;     -- Timing parameter for -8E device
        tAH       : TIME    :=  1.0 ns;
        tAS       : TIME    :=  2.0 ns;
        tCH       : TIME    :=  3.0 ns;
        tCL       : TIME    :=  3.0 ns;
      --   tCK       : TIME    :=  7.5 ns;          -- 133mhz operation
        tCK       : TIME    :=  10.0 ns;          -- 100mhz operation
        tDH       : TIME    :=  1.0 ns;
        tDS       : TIME    :=  2.0 ns;
        tCKH      : TIME    :=  1.0 ns;
        tCKS      : TIME    :=  2.0 ns;
        tCMH      : TIME    :=  1.0 ns;
        tCMS      : TIME    :=  2.0 ns;
        tHZ       : TIME    :=  6.0 ns;
        tOH       : TIME    :=  3.0 ns;
        tMRD      : INTEGER :=  2;
        tRAS      : TIME    := 50.0 ns;
        tRC       : TIME    := 70.0 ns;
        tRCD      : TIME    := 20.0 ns;
        tRP       : TIME    := 20.0 ns;
        tRRD      : TIME    := 20.0 ns;
        tWR       : INTEGER :=  2;
        addr_bits : INTEGER := 13;
        data_bits : INTEGER := 16;
        col_bits  : INTEGER :=  11
    );
    PORT (
        Dq    : INOUT STD_LOGIC_VECTOR (data_bits - 1 DOWNTO 0) := (OTHERS => 'Z');
        Addr  : IN    STD_LOGIC_VECTOR (addr_bits - 1 DOWNTO 0) := (OTHERS => '0');
        Ba    : IN    STD_LOGIC_VECTOR := "00";
        Clk   : IN    STD_LOGIC := '0';
        Cke   : IN    STD_LOGIC := '0';
        Cs_n  : IN    STD_LOGIC := '1';
        Ras_n : IN    STD_LOGIC := '0';
        Cas_n : IN    STD_LOGIC := '0';
        We_n  : IN    STD_LOGIC := '0';
        Dqm   : IN    STD_LOGIC_VECTOR (1 DOWNTO 0) := "00"
    );
END component;

	signal clk_mem, clk_off : std_logic ;
	signal resetn  : std_logic ;
	signal test_done, test_failed : std_logic ;
	
	signal test_addr : std_logic_vector(23 downto 0);
   signal read_request, write_request, data_valid, sdram_pending : std_logic ;
   
   signal mem_data_out, mem_data_in : std_logic_vector(31 downto 0);
	
	signal 	DRAM_ADDR   :   STD_LOGIC_VECTOR (12 downto 0);
	signal 	DRAM_BA      :    STD_LOGIC_VECTOR (1 downto 0);
	signal	DRAM_CAS_N   :    STD_LOGIC;
	signal	DRAM_CKE      :    STD_LOGIC;
	signal	DRAM_CLK      :    STD_LOGIC;
	signal	DRAM_CS_N   :    STD_LOGIC;
	signal	DRAM_DQ      :  STD_LOGIC_VECTOR(15 downto 0);
	signal	DRAM_DQM      :    STD_LOGIC_VECTOR(1 downto 0);
	signal	DRAM_RAS_N   :    STD_LOGIC;
	signal	DRAM_WE_N    :    STD_LOGIC ;
	
	constant clk_period : time := 10 ns;
	
begin


sdram_cmp : mt48lc8m16a2 
    PORT map(
        Dq    => DRAM_DQ,
        Addr  => DRAM_ADDR,
        Ba    => DRAM_BA,
        Clk   => DRAM_CLK,
        Cke   => DRAM_CKE,
        Cs_n  => DRAM_CS_N,
        Ras_n => DRAM_RAS_N,
        Cas_n => DRAM_CAS_N,
        We_n  => DRAM_WE_N,
        Dqm  => DRAM_DQM
    );


sdram_ctrl0 : sdram_controller
  generic map(
    HIGH_BIT => 25,
    MHZ => 100,
    REFRESH_CYCLES => 8192,
    ADDRESS_BITS=> 13
  )
  port map(
      clock_100 => clk_mem,
      clock_100_delayed_3ns => clk_off,
      rst => (NOT resetn),

   -- Signals to/from the SDRAM chip
   DRAM_ADDR   => DRAM_ADDR,
   DRAM_BA      => DRAM_BA,
   DRAM_CAS_N  => DRAM_CAS_N,
   DRAM_CKE    => DRAM_CKE ,
   DRAM_CLK    => DRAM_CLK,
   DRAM_CS_N  => DRAM_CS_N,
   DRAM_DQ     => DRAM_DQ,
   DRAM_DQM     => DRAM_DQM ,
   DRAM_RAS_N   => DRAM_RAS_N,
   DRAM_WE_N    => DRAM_WE_N,

   pending => sdram_pending,

   --- Inputs from rest of the system
   address     => test_addr,
   req_read    => read_request,
   req_write   => write_request,
   data_out    => mem_data_out,
   data_out_valid => data_valid,
   data_in      => mem_data_in,
   data_mask    => "1111"
   );

tester0 : sdram_tester
generic map(ADDR_WIDTH => 24,
		DATA_WIDTH => 32 )
port map(
	clk => clk_mem, resetn => resetn ,
	address => test_addr,
	data_in => mem_data_out,
	data_out => mem_data_in,
	rd => read_request,
	wr => write_request,
	pending => sdram_pending,
	data_valid => data_valid,
	
	test_done => test_done,
	test_failed => test_failed
	);


 clk_mem_process :process
   begin
		clk_mem <= '0';
		wait for clk_period/2;
		clk_mem <= '1';
		wait for clk_period/2;
   end process;
	
	
 clk_off_process :process
   begin
		wait for 3 ns ;
		loop1 : while true loop
			clk_off <= '0';
			wait for clk_period/2;
			clk_off <= '1';
			wait for clk_period/2;
		end loop loop1 ;
   end process;
	
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


end Behavioral;

