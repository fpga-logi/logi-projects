----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:33:02 07/30/2013 
-- Design Name: 
-- Module Name:    logibone_wishbone - Behavioral 
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

library work ;
use work.logi_wishbone_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;

entity logibone_wishbone is
port( OSC_FPGA : in std_logic;
		PB : in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(1 downto 0);	
		
		--gpmc interface
		GPMC_CSN : in std_logic ;
		GPMC_BEN:	in std_logic_vector(1 downto 0);
		GPMC_WEN, GPMC_OEN, GPMC_ADVN :	in std_logic;
		GPMC_CLK :	out std_logic;
		GPMC_AD :	inout std_logic_vector(15 downto 0)	
);
end logibone_wishbone;

architecture Behavioral of logibone_wishbone is

	component clock_gen
	port
	(-- Clock in ports
		CLK_IN1           : in     std_logic;
		-- Clock out ports
		CLK_OUT1          : out    std_logic;
		CLK_OUT2          : out    std_logic;
		-- Status and control signals
		LOCKED            : out    std_logic
	);
	end component;

 -- syscon
 signal sys_reset, sys_clk, clock_locked : std_logic ;
 signal clk_100Mhz, clk_50Mhz : std_logic ;
 -- wrapper
 signal intercon_wrapper_wbm_address :  std_logic_vector(15 downto 0);
 signal intercon_wrapper_wbm_readdata :  std_logic_vector(15 downto 0);
 signal intercon_wrapper_wbm_writedata :  std_logic_vector(15 downto 0);
 signal intercon_wrapper_wbm_strobe :  std_logic;
 signal intercon_wrapper_wbm_write :  std_logic;
 signal intercon_wrapper_wbm_ack :  std_logic;
 signal intercon_wrapper_wbm_cycle :  std_logic;


 signal loopback_sig : std_logic_vector(15 downto 0);
begin

sys_reset <= NOT PB(0); 

pll0 : clock_gen
  port map
   (-- Clock in ports
    CLK_IN1 => OSC_FPGA,
    -- Clock out ports
    CLK_OUT1 => clk_100Mhz,
    CLK_OUT2 => clk_50Mhz,
    -- Status and control signals
    LOCKED => clock_locked);

sys_clk <= clk_100Mhz ;
GPMC_CLK <= clk_50Mhz;


gpmc2wishbone : gpmc_wishbone_wrapper 
port map
    (
      -- GPMC SIGNALS
      gpmc_ad => GPMC_AD, 
      gpmc_csn => GPMC_CSN,
      gpmc_oen => GPMC_OEN,
		gpmc_wen => GPMC_WEN,
		gpmc_advn => GPMC_ADVN,
		
      -- Global Signals
      gls_reset => sys_reset,
      gls_clk   => sys_clk,
      -- Wishbone interface signals
      wbm_address    => intercon_wrapper_wbm_address,  -- Address bus
      wbm_readdata   => intercon_wrapper_wbm_readdata,  -- Data bus for read access
      wbm_writedata 	=> intercon_wrapper_wbm_writedata,  -- Data bus for write access
      wbm_strobe     => intercon_wrapper_wbm_strobe,                      -- Data Strobe
      wbm_write      => intercon_wrapper_wbm_write,                      -- Write access
      wbm_ack        => intercon_wrapper_wbm_ack,                      -- acknowledge
      wbm_cycle      => intercon_wrapper_wbm_cycle                       -- bus cycle in progress
    );


-- Intercon -----------------------------------------------------------
-- no intercon, direct connection to register with no address decoding
-----------------------------------------------------------------------

register0 : wishbone_register
	 port map
	 (
		  -- Syscon signals
		  gls_reset   => sys_reset ,
		  gls_clk     => sys_clk ,
		  -- Wishbone signals
		  wbs_add      => '0' ,
		  wbs_writedata => intercon_wrapper_wbm_writedata,
		  wbs_readdata  => intercon_wrapper_wbm_readdata,
		  wbs_strobe    => intercon_wrapper_wbm_strobe,
		  wbs_cycle     => intercon_wrapper_wbm_cycle,
		  wbs_write     => intercon_wrapper_wbm_write,
		  wbs_ack       => intercon_wrapper_wbm_ack,
		  -- out signals
		  reg_out => loopback_sig,
		  reg_in => loopback_sig
	 );
	LED <= loopback_sig(1 downto 0);

end Behavioral;

