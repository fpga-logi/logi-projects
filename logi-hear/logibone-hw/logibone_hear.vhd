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

entity logibone_hear is
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
end logibone_hear;

architecture Behavioral of logibone_hear is

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
	
	component aes_rx
	port (
	  clk:                    in  std_logic;     
	  rst:                    in  std_logic;     
	  din:                    in  std_logic;     
	  mux_mode:               in  std_logic;     
	  locked:                 out std_logic;     
	  chan1_en:               out std_logic;     
	  audio1:                 out std_logic_vector(23 downto 0);
	  valid1:                 out std_logic; 
	  user1:                  out std_logic; 
	  cs1:                    out std_logic; 
	  chan2_en:               out std_logic; 
	  audio2:                 out std_logic_vector(23 downto 0);
	  valid2:                 out std_logic;   
	  user2:                  out std_logic;   
	  cs2:                    out std_logic;   
	  parity_err:             out std_logic;   
	  frames:                 out std_logic_vector(7 downto 0);
	  frame0:                 out std_logic);
	end component;
	
	component aes_rx_rate_detect
	 generic (
		  CNTR_WIDTH:             integer := 14;      
		  CMP_VAL_LSB:            integer := 6;       
		  CLOCK_FREQUENCY:        integer := 133333333;
		  JITTER_ALLOWANCE:       integer := 1);       
	 port (
		  clk:                    in  std_logic;       
		  rst:                    in  std_logic;       
		  strobe:                 in  std_logic;       
		  detect:                 out std_logic;       
		  rate:                   out std_logic_vector(3 downto 0));
	end component;
	
	component samples2fifo is
		port(
			clk, rst : in std_logic ;
			
			frame_info : in std_logic_vector(15 downto 0);
			frame0 : in std_logic ;
			data : in std_logic_vector(23 downto 0);
			data_valid : in std_logic ;
			
			
			fifo_write : out std_logic ;
			fifo_data : out std_logic_vector(15 downto 0);
			fifo_full : in std_logic 
		);
	end component;
	
	component spdif_48k_ds is
		port(
			clk, reset : in std_logic ;
			
			rate_in : in std_logic_vector(3 downto 0);
			frame0_in : in std_logic ;
			chan1_en_in, chan2_en_in : in std_logic ;
			data_in : in std_logic_vector(23 downto 0);
			
			
			rate_out : out std_logic_vector(3 downto 0);
			frame0_out : out std_logic ;
			data_out : out std_logic_vector(23 downto 0);
			chan1_en_out, chan2_en_out : out std_logic 
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
	
	signal intercon_intr_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_intr_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_intr_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_intr_wbm_strobe :  std_logic;
	signal intercon_intr_wbm_write :  std_logic;
	signal intercon_intr_wbm_ack :  std_logic;
	signal intercon_intr_wbm_cycle :  std_logic;
	
	signal fifo0_cs, reg_cs, intr_cs : std_logic ;

	-- fifo signals
	signal fifo_output : std_logic_vector(15 downto 0);
	signal fifo_input : std_logic_vector(15 downto 0);
	signal fifoB_wr, fifoA_rd, fifoA_rd_old, fifoA_empty, fifoA_full, fifoB_empty, fifoB_full : std_logic ;

-- registers signals
	signal loopback_sig : std_logic_vector(15 downto 0);
	signal control_register : std_logic_vector(15 downto 0);
	signal flag_register : std_logic_vector(15 downto 0);
	
-- intr manager signals
	signal fifo_burst : std_logic ;

-- AES receiver signals

subtype aes_audio_sample_type is std_logic_vector(23 downto 0);
subtype aes_frame_counter_type is std_logic_vector(7 downto 0);
subtype aes_rate_type is std_logic_vector(3 downto 0);

-- AES Rx #1 signals
signal aes1_rx :            std_logic;                      -- input bit stream
signal parity_err1 :        std_logic;                      -- parity err signal
signal err_capture1 :       std_logic;                      -- parity err capture FF
signal err_cap_rst :        std_logic;                      -- error capture reset
signal aes1_locked :        std_logic;                      -- Rx locked
signal channel1, ds_channel1 :           std_logic;                      -- ch 1 enable
signal channel2, ds_channel1 :           std_logic;                      -- ch 2 enable
signal audio1_out :         aes_audio_sample_type;          -- ch 1 audio data
signal audio2_out, ds_data_out :         aes_audio_sample_type;          -- ch 2 audio data
signal valid1_out :         std_logic;                      -- ch 1 valid bit
signal valid2_out :         std_logic;                      -- ch 2 valid bit
signal user1_out :          std_logic;                      -- ch 1 user bit
signal user2_out :          std_logic;                      -- ch 2 user bit
signal cs1_out :            std_logic;                      -- ch 1 ch status
signal cs2_out :            std_logic;                      -- ch 2 ch status
signal aes_frame_count1 :   aes_frame_counter_type;         -- frame counter
signal aes_frame0, ds_frame0 :         std_logic;                      -- 1 = first frame
signal cs1_crc_out :        std_logic;                      -- ch 1 C CRC bit
signal cs1_crc_out_en :     std_logic;                      -- ch 1 C CRC enable
signal cs1_crc_err :        std_logic;                      -- ch 1 C CRC err capture
signal cs1_crc_err_det :    std_logic;                      -- ch 1 C CRC err detect
signal cs2_crc_out :        std_logic;                      -- ch 2 C CRC bit
signal cs2_crc_out_en :     std_logic;                      -- ch 2 C CRC enable
signal cs2_crc_err :        std_logic;                      -- ch 2 C CRC err capture
signal cs2_crc_err_det :    std_logic;                      -- ch 2 C CRC err detect
signal rate_detect :        std_logic;                      -- 1 if valid AES rate
signal rate, ds_rate :               aes_rate_type;                  -- detected AES rate



signal rst_audio_pipeline : std_logic ;
signal sample_valid : std_logic ;
signal frame_info : std_logic_vector(15 downto 0);
begin

ARD_SCL <= 'Z' ;
ARD_SDA <= 'Z' ;

LED(1) <= (GPMC_BEN(0) XOR GPMC_BEN(1)) ;
LED(0) <= aes_frame0 and sample_valid;
sys_reset <= NOT PB(0); 
sys_resetn <= NOT sys_reset ; -- for preipherals with active low reset

pll0 : clock_gen
  port map
   (-- Clock in ports
    CLK_IN1 => OSC_FPGA,
    -- Clock out ports
    CLK_OUT1 => clk_100Mhz,
    CLK_OUT2 => clk_120Mhz,
	 CLK_OUT3 => clk_150Mhz,
    -- Status and control signals
    LOCKED => clock_locked);

sys_clk <= clk_120Mhz ;
audio_clk <= clk_120Mhz ;
--GPMC_CLK <= clk_50Mhz;


gpmc2wishbone : gpmc_wishbone_wrapper 
generic map(sync => false, burst => false)
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

				
reg_cs <= '1' when intercon_wrapper_wbm_address(15 downto 2) = "0000100000000"   else
			 '0' ;
			 
intr_cs <= '1' when intercon_wrapper_wbm_address(15 downto 2) = "0000100000001"   else
			  '0' ;


intercon_fifo0_wbm_address <= intercon_wrapper_wbm_address ;
intercon_fifo0_wbm_writedata <= intercon_wrapper_wbm_writedata ;
intercon_fifo0_wbm_write <= intercon_wrapper_wbm_write and fifo0_cs ;
intercon_fifo0_wbm_strobe <= intercon_wrapper_wbm_strobe and fifo0_cs ;
intercon_fifo0_wbm_cycle <= intercon_wrapper_wbm_cycle and fifo0_cs ;

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
											intercon_intr_wbm_readdata when intr_cs = '1' else
											intercon_wrapper_wbm_address ;
											
intercon_wrapper_wbm_ack	<= intercon_register_wbm_ack when reg_cs = '1' else
										intercon_fifo0_wbm_ack when fifo0_cs = '1' else
										intercon_intr_wbm_ack when intr_cs = '1' else
										'0' ;
									      
										  
-----------------------------------------------------------------------

	register0 : wishbone_register
		 generic map(nb_regs => 2)
		 port map
		 (
			  -- Syscon signals
			  gls_reset   => sys_reset ,
			  gls_clk     => sys_clk ,
			  -- Wishbone signals
			  wbs_add      =>  intercon_register_wbm_address ,
			  wbs_writedata => intercon_register_wbm_writedata,
			  wbs_readdata  => intercon_register_wbm_readdata,
			  wbs_strobe    => intercon_register_wbm_strobe,
			  wbs_cycle     => intercon_register_wbm_cycle,
			  wbs_write     => intercon_register_wbm_write,
			  wbs_ack       => intercon_register_wbm_ack,
			  -- out signals
			  reg_out(0) => loopback_sig,
			  reg_out(1) => control_register,
			  --reg_out(2) => , to be used to connect reset of audio 
			  reg_in(0) => loopback_sig,
			  reg_in(1) => flag_register
			  --reg_in(2) => , to be used to connect error flags
		 );
	--LED(0) <= loopback_sig(0);
	
	
	fifo0: wishbone_fifo
		generic map(
				SIZE	=> 4096,
				B_BURST_SIZE => 512,
				SYNC_LOGIC_INTERFACE => true)
		port map(
			-- Syscon signals
			gls_reset    => sys_reset,
			gls_clk      => sys_clk,
			-- Wishbone signals
			wbs_add      =>  intercon_fifo0_wbm_address ,
			wbs_writedata => intercon_fifo0_wbm_writedata,
			wbs_readdata  => intercon_fifo0_wbm_readdata,
			wbs_strobe    => intercon_fifo0_wbm_strobe,
			wbs_cycle     => intercon_fifo0_wbm_cycle,
			wbs_write     => intercon_fifo0_wbm_write,
			wbs_ack       => intercon_fifo0_wbm_ack,
				  
			-- logic signals  

			wrB => fifoB_wr,
			rdA => fifoA_rd,
			inputB => fifo_input, 
			outputA => fifo_output,
			emptyA => fifoA_empty,
			fullA => fifoA_full,
			emptyB => fifoB_empty,
			fullB => fifoB_full,
			burst_available_B => fifo_burst
	);
	
	
	intr_manager : wishbone_interrupt_manager
		generic map(NB_INTERRUPT_LINES => 1, 
		  NB_INTERRUPTS => 1,
		  ADDR_WIDTH => 16,
		  DATA_WIDTH => 16)
		port map(
			-- Syscon signals
			gls_reset    => sys_reset,
			gls_clk      => sys_clk,
			-- Wishbone signals
			wbs_add      =>  intercon_intr_wbm_address ,
			wbs_writedata => intercon_intr_wbm_writedata,
			wbs_readdata  => intercon_intr_wbm_readdata,
			wbs_strobe    => intercon_intr_wbm_strobe,
			wbs_cycle     => intercon_intr_wbm_cycle,
			wbs_write     => intercon_intr_wbm_write,
			wbs_ack       => intercon_intr_wbm_ack,

			interrupt_lines => open,
			interrupts_req(0) => fifo_burst

		);


-- audio pipeline

	rst_audio_pipeline <= control_register(0);
	
	
	----------------------------------------------------------------------------
 -- AES audio receivers
 --
 
 IBUFAESRX1 : IBUF
    generic map (
        IOSTANDARD          => "LVCMOS25")
    port map (
        I                   => PMOD2(7),
        O                   => aes1_rx);
 
 
 AESRX1 : aes_rx
 port map (
	  clk                 => audio_clk,
	  rst                 => sys_reset,
	  din                 => aes1_rx,
	  mux_mode            => '1', -- muxed mode
	  locked              => aes1_locked,
	  chan1_en            => channel1,
	  audio1              => audio1_out,
	  valid1              => valid1_out,
	  user1               => user1_out,
	  cs1                 => cs1_out,
	  chan2_en            => channel2,
	  audio2              => audio2_out,
	  valid2              => valid2_out,
	  user2               => user2_out,
	  cs2                 => cs2_out,
	  parity_err          => parity_err1,
	  frames              => aes_frame_count1,
	  frame0              => aes_frame0);


err_cap_rst <= control_register(0) ;
flag_register(13 downto 0) <= parity_err1 & aes1_locked & rate & aes_frame_count1;

 process(audio_clk, err_cap_rst)
 begin
	  if err_cap_rst = '1' then
			err_capture1 <= '0';
	  elsif rising_edge(audio_clk) then
			if channel2 = '1' and parity_err1 = '1' then
				 err_capture1 <= '1';
			end if;
	  end if;
 end process;

 RDET : aes_rx_rate_detect
 generic map (
	  CLOCK_FREQUENCY     => 120000000,
	  CMP_VAL_LSB         => 4,
	  JITTER_ALLOWANCE    => 2)
 port map (
	  clk                 => audio_clk,
	  rst                 => sys_reset,
	  strobe              => channel2,
	  detect              => rate_detect,
	  rate                => rate);


 
 ds_48k_0 : spdif_48k_ds
		port map(
			clk => audio_clk, 
			reset => sys_reset,
			
			rate_in => rate ,
			frame0_in => aes_frame0,
			chan1_en_in => channel1, chan2_en_in => channel2,
			data_in => audio2_out,
			
			
			rate_out => ds_rate,
			frame0_out => ds_frame0,
			data_out => ds_data_out,
			chan1_en_out => ds_channel1, 
			chan2_en_out => ds_channel2
		);
	 
	 frame_info(3 downto 0) <= ds_rate ;
    sample_valid <= ds_channel2 OR ds_channel1 ;
 
 
 samples_to_fifo_0 : samples2fifo
	port map (
	  clk                 => audio_clk,
	  rst                 => rst_audio_pipeline, -- controled through register to guarantuee alignement of data on frame
	  
	  frame0 => ds_frame0 ,
	  
	  frame_info => frame_info ,
	  data			     => ds_data_out,
	  data_valid				=> sample_valid,
	  
	  
	  fifo_write => fifoB_wr,
	  fifo_data => fifo_input,
	  fifo_full => fifoB_full
	  );



end Behavioral;

