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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library unisim; 
use unisim.vcomponents.all; 

library work ;
use work.logi_wishbone_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;

entity logibone_hear_v2 is
port( OSC_FPGA : in std_logic;
		PB : in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(1 downto 0);	
		
		--gpmc interface
		GPMC_CSN1 : in std_logic ;
		GPMC_BEN:	in std_logic_vector(1 downto 0);
		GPMC_WEN, GPMC_OEN, GPMC_ADVN :	in std_logic;
		GPMC_CLK :	in std_logic;
		GPMC_AD :	inout std_logic_vector(15 downto 0);
		
		
		ARD_SCL, ARD_SDA : inout std_logic ;

		PMOD1 : inout std_logic_vector(7 downto 0);
		PMOD2 : inout std_logic_vector(7 downto 0)	
);
end logibone_hear_v2;

architecture Behavioral of logibone_hear_v2 is

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
	
	
	
	
	
	component hear_aes_receiver is
		generic(nb_aes_channel : positive := 3; 
				wb_data_width : positive := 16;
				wb_add_width : positive := 16 ;
				CLOCK_FREQUENCY   : positive := 120000000;
				CMP_VAL_LSB       : positive := 4;
				JITTER_ALLOWANCE  : positive := 2
				);
		port(
				-- Syscon signals
			gls_reset    : in std_logic ;
			gls_clk      : in std_logic ;
			
			audio_reset : in std_logic ;
			audio_clk : in std_logic ;
			aes_rx_input : in std_logic_vector(nb_aes_channel-1 downto 0) ;
			
			fifo_wr : out std_logic_vector(nb_aes_channel-1 downto 0) ;
			fifo_full : in std_logic_vector(nb_aes_channel-1 downto 0) ;
			fifo_data : out slv16_array(nb_aes_channel-1 downto 0);
			
			flag_register : out slv16_array(nb_aes_channel-1 downto 0);
			control_register : in slv16_array(nb_aes_channel-1 downto 0)
			
		);
	end component;

	-- syscon
	signal sys_reset, sys_resetn,sys_clk, clock_locked,audio_clk : std_logic ;
	signal clk_100Mhz, clk_120Mhz, clk_150Mhz : std_logic ;

	-- wishbone intercon signals
	signal intercon_wrapper_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_strobe :  std_logic;
	signal intercon_wrapper_wbm_write :  std_logic;
	signal intercon_wrapper_wbm_ack :  std_logic;
	signal intercon_wrapper_wbm_cycle :  std_logic;

	signal intercon_register_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_register_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_register_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_register_wbm_strobe :  std_logic;
	signal intercon_register_wbm_write :  std_logic;
	signal intercon_register_wbm_ack :  std_logic;
	signal intercon_register_wbm_cycle :  std_logic;

	signal intercon_fifo0_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_fifo0_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_fifo0_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_fifo0_wbm_strobe :  std_logic;
	signal intercon_fifo0_wbm_write :  std_logic;
	signal intercon_fifo0_wbm_ack :  std_logic;
	signal intercon_fifo0_wbm_cycle :  std_logic;
	
	signal intercon_fifo1_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_fifo1_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_fifo1_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_fifo1_wbm_strobe :  std_logic;
	signal intercon_fifo1_wbm_write :  std_logic;
	signal intercon_fifo1_wbm_ack :  std_logic;
	signal intercon_fifo1_wbm_cycle :  std_logic;
	
	signal intercon_fifo2_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_fifo2_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_fifo2_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_fifo2_wbm_strobe :  std_logic;
	signal intercon_fifo2_wbm_write :  std_logic;
	signal intercon_fifo2_wbm_ack :  std_logic;
	signal intercon_fifo2_wbm_cycle :  std_logic;
	
	signal intercon_intr_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_intr_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_intr_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_intr_wbm_strobe :  std_logic;
	signal intercon_intr_wbm_write :  std_logic;
	signal intercon_intr_wbm_ack :  std_logic;
	signal intercon_intr_wbm_cycle :  std_logic;
	
	signal fifo0_cs, fifo1_cs, fifo2_cs, reg_cs, intr_cs : std_logic ;

	-- fifo signals
	signal fifo0_data, fifo1_data, fifo2_data: std_logic_vector(15 downto 0);
	signal fifo0_wr, fifo1_wr, fifo2_wr, fifo0_full, fifo1_full, fifo2_full : std_logic ;

-- registers signals
	signal loopback_sig : std_logic_vector(15 downto 0);
	signal rec0_ctrl, rec1_ctrl, rec2_ctrl, rec0_flags, rec1_flags, rec2_flags : std_logic_vector(15 downto 0);
	
-- intr manager signals
	signal fifo0_burst, fifo1_burst, fifo2_burst : std_logic ;

-- AES Rx #1 signals
signal aes0_rx, aes1_rx, aes2_rx :            std_logic;                      -- input bit stream

signal rst_audio_pipeline : std_logic ;

begin

ARD_SCL <= 'Z' ;
ARD_SDA <= 'Z' ;

LED(1) <= fifo0_full ;
LED(0) <= fifo0_wr ; -- should give an indication of SPDIF working
sys_reset <= NOT PB(0); 
sys_resetn <= NOT sys_reset ; -- for preipherals with active low reset

pll0 : clock_gen
  port map
   (-- Clock in ports
    CLK_IN1 => OSC_FPGA,
    -- Clock out ports
    CLK_OUT1 => clk_100Mhz,
    CLK_OUT2 => clk_120Mhz,
    -- Status and control signals
    LOCKED => clock_locked);

sys_clk <= clk_100Mhz ;
audio_clk <= clk_100Mhz ;
--GPMC_CLK <= clk_50Mhz;


gpmc2wishbone : gpmc_wishbone_wrapper 
generic map(sync => true, burst => false)
port map
    (
      -- GPMC SIGNALS
      gpmc_ad => GPMC_AD, 
      gpmc_csn => GPMC_CSN1,
      gpmc_oen => GPMC_OEN,
		gpmc_wen => GPMC_WEN,
		gpmc_advn => GPMC_ADVN,
		gpmc_clk => GPMC_CLK,
		
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
-- will be generated automatically in the future

fifo0_cs <= '1' when intercon_wrapper_wbm_address(15 downto 11) = "00000" else
				'0' ;
				
fifo1_cs <= '1' when intercon_wrapper_wbm_address(15 downto 11) = "00001" else
				'0' ;

fifo2_cs <= '1' when intercon_wrapper_wbm_address(15 downto 11) = "00010" else
				'0' ;

				
reg_cs <= '1' when intercon_wrapper_wbm_address(15 downto 2) = "0011000000000"   else
			 '0' ;
			 
intr_cs <= '1' when intercon_wrapper_wbm_address(15 downto 2) = "0010000000001"   else
			  '0' ;


intercon_fifo0_wbm_address <= intercon_wrapper_wbm_address ;
intercon_fifo0_wbm_writedata <= intercon_wrapper_wbm_writedata ;
intercon_fifo0_wbm_write <= intercon_wrapper_wbm_write and fifo0_cs ;
intercon_fifo0_wbm_strobe <= intercon_wrapper_wbm_strobe and fifo0_cs ;
intercon_fifo0_wbm_cycle <= intercon_wrapper_wbm_cycle and fifo0_cs ;

intercon_fifo1_wbm_address <= intercon_wrapper_wbm_address ;
intercon_fifo1_wbm_writedata <= intercon_wrapper_wbm_writedata ;
intercon_fifo1_wbm_write <= intercon_wrapper_wbm_write and fifo1_cs ;
intercon_fifo1_wbm_strobe <= intercon_wrapper_wbm_strobe and fifo1_cs ;
intercon_fifo1_wbm_cycle <= intercon_wrapper_wbm_cycle and fifo1_cs ;

intercon_fifo2_wbm_address <= intercon_wrapper_wbm_address ;
intercon_fifo2_wbm_writedata <= intercon_wrapper_wbm_writedata ;
intercon_fifo2_wbm_write <= intercon_wrapper_wbm_write and fifo2_cs ;
intercon_fifo2_wbm_strobe <= intercon_wrapper_wbm_strobe and fifo2_cs ;
intercon_fifo2_wbm_cycle <= intercon_wrapper_wbm_cycle and fifo2_cs ;

intercon_register_wbm_address <= intercon_wrapper_wbm_address ;
intercon_register_wbm_writedata <= intercon_wrapper_wbm_writedata ;
intercon_register_wbm_write <= intercon_wrapper_wbm_write and reg_cs ;
intercon_register_wbm_strobe <= intercon_wrapper_wbm_strobe and reg_cs ;
intercon_register_wbm_cycle <= intercon_wrapper_wbm_cycle and reg_cs ;									

intercon_intr_wbm_address <= intercon_wrapper_wbm_address ;
intercon_intr_wbm_writedata <= intercon_wrapper_wbm_writedata ;
intercon_intr_wbm_write <= intercon_wrapper_wbm_write and intr_cs ;
intercon_intr_wbm_strobe <= intercon_wrapper_wbm_strobe and intr_cs ;
intercon_intr_wbm_cycle <= intercon_wrapper_wbm_cycle and intr_cs ;	

intercon_wrapper_wbm_readdata	<= intercon_register_wbm_readdata when reg_cs = '1' else
											intercon_fifo0_wbm_readdata when fifo0_cs = '1' else
											intercon_fifo1_wbm_readdata when fifo1_cs = '1' else
											intercon_fifo2_wbm_readdata when fifo2_cs = '1' else
											intercon_intr_wbm_readdata when intr_cs = '1' else
											intercon_wrapper_wbm_address ;
											
intercon_wrapper_wbm_ack	<= intercon_register_wbm_ack when reg_cs = '1' else
										intercon_fifo0_wbm_ack when fifo0_cs = '1' else
										intercon_fifo1_wbm_ack when fifo1_cs = '1' else
										intercon_fifo2_wbm_ack when fifo2_cs = '1' else
										intercon_intr_wbm_ack when intr_cs = '1' else
										'0' ;
									      
										  
-----------------------------------------------------------------------

	register0 : wishbone_register
		 generic map(nb_regs => 4)
		 port map
		 (
			  -- Syscon signals
			  gls_reset   => sys_reset ,
			  gls_clk     => sys_clk ,
			  -- Wishbone signals
			  wbs_address      =>  intercon_register_wbm_address ,
			  wbs_writedata => intercon_register_wbm_writedata,
			  wbs_readdata  => intercon_register_wbm_readdata,
			  wbs_strobe    => intercon_register_wbm_strobe,
			  wbs_cycle     => intercon_register_wbm_cycle,
			  wbs_write     => intercon_register_wbm_write,
			  wbs_ack       => intercon_register_wbm_ack,
			  -- out signals
			  reg_out(0) => loopback_sig,
			  reg_out(1) => rec0_ctrl,
			  reg_out(2) => rec1_ctrl,
			  reg_out(3) => rec2_ctrl,
			  --reg_out(2) => , to be used to connect reset of audio 
			  reg_in(0) => loopback_sig,
			  reg_in(1) => rec0_flags,
			  reg_in(2) => rec1_flags,
			  reg_in(3) => rec2_flags
			  --reg_in(2) => , to be used to connect error flags
		 );
	--LED(0) <= loopback_sig(0);
	
	
	fifo0: wishbone_fifo
		generic map(
				SIZE	=> 4096,
				B_BURST_SIZE => 512,
				SYNC_LOGIC_INTERFACE => true,
				AUTO_INC => false)
		port map(
			-- Syscon signals
			gls_reset    => sys_reset,
			gls_clk      => sys_clk,
			-- Wishbone signals
			wbs_address      =>  intercon_fifo0_wbm_address ,
			wbs_writedata => intercon_fifo0_wbm_writedata,
			wbs_readdata  => intercon_fifo0_wbm_readdata,
			wbs_strobe    => intercon_fifo0_wbm_strobe,
			wbs_cycle     => intercon_fifo0_wbm_cycle,
			wbs_write     => intercon_fifo0_wbm_write,
			wbs_ack       => intercon_fifo0_wbm_ack,
				  
			-- logic signals  

			wrB => fifo0_wr,
			rdA => '0',
			inputB => fifo0_data, 
			outputA => open,
			emptyA => open,
			fullA => open,
			emptyB => open,
			fullB => fifo0_full,
			burst_available_B => fifo0_burst
	);
	
		fifo1: wishbone_fifo
		generic map(
				SIZE	=> 4096,
				B_BURST_SIZE => 512,
				SYNC_LOGIC_INTERFACE => true)
		port map(
			-- Syscon signals
			gls_reset    => sys_reset,
			gls_clk      => sys_clk,
			-- Wishbone signals
			wbs_address      =>  intercon_fifo1_wbm_address ,
			wbs_writedata => intercon_fifo1_wbm_writedata,
			wbs_readdata  => intercon_fifo1_wbm_readdata,
			wbs_strobe    => intercon_fifo1_wbm_strobe,
			wbs_cycle     => intercon_fifo1_wbm_cycle,
			wbs_write     => intercon_fifo1_wbm_write,
			wbs_ack       => intercon_fifo1_wbm_ack,
				  
			-- logic signals  

			wrB => fifo1_wr,
			rdA => '0',
			inputB => fifo1_data, 
			outputA => open,
			emptyA => open,
			fullA => open,
			emptyB => open,
			fullB => fifo1_full,
			burst_available_B => fifo1_burst
	);
	
		fifo2: wishbone_fifo
		generic map(
				SIZE	=> 4096,
				B_BURST_SIZE => 512,
				SYNC_LOGIC_INTERFACE => true)
		port map(
			-- Syscon signals
			gls_reset    => sys_reset,
			gls_clk      => sys_clk,
			-- Wishbone signals
			wbs_address      =>  intercon_fifo2_wbm_address ,
			wbs_writedata => intercon_fifo2_wbm_writedata,
			wbs_readdata  => intercon_fifo2_wbm_readdata,
			wbs_strobe    => intercon_fifo2_wbm_strobe,
			wbs_cycle     => intercon_fifo2_wbm_cycle,
			wbs_write     => intercon_fifo2_wbm_write,
			wbs_ack       => intercon_fifo2_wbm_ack,
				  
			-- logic signals  

			wrB => fifo2_wr,
			rdA => '0',
			inputB => fifo2_data, 
			outputA => open,
			emptyA => open,
			fullA => open,
			emptyB => open,
			fullB => fifo2_full,
			burst_available_B => fifo2_burst
	);
	
	
	intr_manager : wishbone_interrupt_manager
		generic map(NB_INTERRUPT_LINES => 1, 
		  NB_INTERRUPTS => 3,
		  ADDR_WIDTH => 16,
		  DATA_WIDTH => 16)
		port map(
			-- Syscon signals
			gls_reset    => sys_reset,
			gls_clk      => sys_clk,
			-- Wishbone signals
			wbs_address      =>  intercon_intr_wbm_address ,
			wbs_writedata => intercon_intr_wbm_writedata,
			wbs_readdata  => intercon_intr_wbm_readdata,
			wbs_strobe    => intercon_intr_wbm_strobe,
			wbs_cycle     => intercon_intr_wbm_cycle,
			wbs_write     => intercon_intr_wbm_write,
			wbs_ack       => intercon_intr_wbm_ack,

			interrupt_lines => open,
			interrupts_req(0) => fifo0_burst,
			interrupts_req(1) => fifo1_burst,
			interrupts_req(2) => fifo2_burst

		);


-- audio pipeline

	rst_audio_pipeline <= rec0_ctrl(0);
	
	
	----------------------------------------------------------------------------
 -- AES audio receivers
 --
 
 IBUFAESRX0 : IBUF
    generic map (
        IOSTANDARD          => "LVCMOS25")
    port map (
        I                   => PMOD2(7),
        O                   => aes0_rx);
		  
 IBUFAESRX1 : IBUF
    generic map (
        IOSTANDARD          => "LVCMOS25")
    port map (
        I                   => PMOD2(6),
        O                   => aes1_rx);
		  
 IBUFAESRX2 : IBUF
    generic map (
        IOSTANDARD          => "LVCMOS25")
    port map (
        I                   => PMOD2(5),
        O                   => aes2_rx);
 
 

aes_receivers : hear_aes_receiver
		generic map(nb_aes_channel => 3,
				wb_data_width => 16,
				wb_add_width =>  16 ,
				CLOCK_FREQUENCY => 100_000_000,
				CMP_VAL_LSB     => 4,
				JITTER_ALLOWANCE  => 2
				)
		port map(
				-- Syscon signals
			gls_reset => sys_reset,
			gls_clk   => sys_clk,
			
			audio_reset => rst_audio_pipeline,
			audio_clk => audio_clk,
			aes_rx_input(0) => aes0_rx,
			aes_rx_input(1) => aes1_rx,
			aes_rx_input(2) => aes2_rx,
			
			fifo_wr(0) => fifo0_wr,
			fifo_wr(1) => fifo1_wr,
			fifo_wr(2) => fifo2_wr,
			fifo_full(0) => fifo0_full ,
			fifo_full(1) => fifo1_full ,
			fifo_full(2) => fifo2_full ,
			fifo_data(0) => fifo0_data,
			fifo_data(1) => fifo1_data,
			fifo_data(2) => fifo2_data,
			
			flag_register(0) => rec0_flags,
			flag_register(1) => rec1_flags,
			flag_register(2) => rec2_flags,
			control_register(0) => rec0_ctrl,
			control_register(1) => rec1_ctrl,
			control_register(2) => rec2_ctrl
			
		);



end Behavioral;

