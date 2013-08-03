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

library work ;
use work.logi_wishbone_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;
use work.image_pack.all ;
use work.filter_pack.all ;

entity logibone_wishbone is
port( OSC_FPGA : in std_logic;
		PB : in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(1 downto 0);	
		
		--gpmc interface
		GPMC_CSN : in std_logic ;
		GPMC_BEN:	in std_logic_vector(1 downto 0);
		GPMC_WEN, GPMC_OEN, GPMC_ADVN :	in std_logic;
		GPMC_CLK :	in std_logic;
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
		CLK_OUT3          : out    std_logic;
		-- Status and control signals
		LOCKED            : out    std_logic
	);
	end component;

	-- syscon
	signal sys_reset, sys_resetn,sys_clk, clock_locked : std_logic ;
	signal clk_100Mhz, clk_120Mhz, clk_24Mhz : std_logic ;

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
	
	signal fifo0_cs, reg_cs : std_logic ;

	-- fifo signals
	signal fifo_output : std_logic_vector(15 downto 0);
	signal fifo_input : std_logic_vector(15 downto 0);
	signal fifoB_wr, fifoA_rd, fifoA_rd_old, fifoA_empty, fifoA_full, fifoB_empty, fifoB_full : std_logic ;

	-- pixel signals
	signal pixel_from_interface : std_logic_vector(7 downto 0);
	signal pxclk_from_interface, href_from_interface, vsync_from_interface : std_logic ;
	signal pixel_from_sobel : std_logic_vector(7 downto 0);
	signal pxclk_from_sobel, href_from_sobel, vsync_from_sobel : std_logic ;
	signal pixel_from_gauss : std_logic_vector(7 downto 0);
	signal pxclk_from_gauss, href_from_gauss, vsync_from_gauss : std_logic ;
	signal pixel_from_hyst : std_logic_vector(7 downto 0);
	signal pxclk_from_hyst, href_from_hyst, vsync_from_hyst : std_logic ;	

	signal output_pxclk, output_href , output_vsync : std_logic ;
	signal output_pixel : std_logic_vector(7 downto 0);
	signal hsync_rising_edge, vsync_rising_edge, pxclk_rising_edge, hsync_old, vsync_old, pxclk_old, write_pixel_old : std_logic ;
	signal pixel_buffer : std_logic_vector(15 downto 0);	
	signal pixel_count :std_logic_vector(7 downto 0);
	signal write_pixel : std_logic ;	

-- registers signals
	signal loopback_sig : std_logic_vector(15 downto 0);

-- configuration
	for all : sobel3x3 use entity work.sobel3x3(RTL) ;
	for all : gauss3x3 use entity work.gauss3x3(RTL) ;
begin

LED(1) <= (GPMC_BEN(0) XOR GPMC_BEN(1)) ;

sys_reset <= NOT PB(0); 
sys_resetn <= NOT sys_reset ; -- for preipherals with active low reset

pll0 : clock_gen
  port map
   (-- Clock in ports
    CLK_IN1 => OSC_FPGA,
    -- Clock out ports
    CLK_OUT1 => clk_100Mhz,
    CLK_OUT2 => clk_120Mhz,
	 CLK_OUT3 => clk_24Mhz,
    -- Status and control signals
    LOCKED => clock_locked);

sys_clk <= clk_120Mhz ;
--GPMC_CLK <= clk_50Mhz;


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
-- will be generated automatically in the future

fifo0_cs <= '1' when intercon_wrapper_wbm_address(15 downto 11) = "00000" else
				'0' ;
				
reg_cs <= '1' when intercon_wrapper_wbm_address(15 downto 11) = "00001"  and intercon_wrapper_wbm_address(0) = '0' else
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


intercon_wrapper_wbm_readdata	<= intercon_register_wbm_readdata when reg_cs = '1' else
											intercon_fifo0_wbm_readdata when fifo0_cs = '1' else
											intercon_wrapper_wbm_address ;
											
intercon_wrapper_wbm_ack	<= intercon_register_wbm_ack when reg_cs = '1' else
										intercon_fifo0_wbm_ack when fifo0_cs = '1' else
										'0' ;
									      
										  
-----------------------------------------------------------------------

register0 : wishbone_register
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
		  reg_out => loopback_sig,
		  reg_in => X"AA55"--loopback_sig
	 );
	LED(0) <= loopback_sig(0);
	
	
	fifo0: wishbone_fifo
		generic map(
				SIZE	=> 4096,
				BURST_SIZE => 1024)
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
			fullB => fifoB_full
	);


-- pixel pipeline

	pixel_from_fifo : fifo2pixel
	generic map(WIDTH => 320 , HEIGHT => 240)
	port map(
		clk => sys_clk, resetn => sys_resetn ,

		-- fifo side
		fifo_empty => fifoA_empty ,
		fifo_rd => fifoA_rd ,
		fifo_data =>fifo_output,
		
		-- pixel side 
		pixel_clk => clk_24Mhz,
		y_data =>  pixel_from_interface , 
 		pixel_clock_out => pxclk_from_interface, 
		hsync_out => href_from_interface, 
		vsync_out =>vsync_from_interface 
	
	);

	gaussian_filter : gauss3x3 
	generic map(WIDTH => 320, HEIGHT => 240)
	port map(
			clk => sys_clk, 
			resetn => sys_resetn ,
			pixel_clock => pxclk_from_interface, hsync => href_from_interface, vsync => vsync_from_interface,
			pixel_clock_out => pxclk_from_gauss, hsync_out => href_from_gauss, vsync_out => vsync_from_gauss,
			pixel_data_in => pixel_from_interface,
			pixel_data_out => pixel_from_gauss
	);

	sobel_filter : sobel3x3 
	generic map(WIDTH => 320, HEIGHT => 240)
	port map(
			clk => sys_clk, 
			resetn => sys_resetn ,
			pixel_clock => pxclk_from_gauss, hsync => href_from_gauss, vsync => vsync_from_gauss,
			pixel_clock_out => pxclk_from_sobel, hsync_out => href_from_sobel, vsync_out => vsync_from_sobel,
			pixel_data_in => pixel_from_gauss,
			pixel_data_out => pixel_from_sobel
	);

	hysteresis : hyst_threshold 
	generic map(WIDTH => 320, HEIGHT => 240, LOW_THRESH => 50 , HIGH_THRESH => 90)
	port map(
			clk => sys_clk, 
			resetn => sys_reset ,
			pixel_clock => pxclk_from_sobel, hsync => href_from_sobel, vsync => vsync_from_sobel,
			pixel_clock_out => pxclk_from_hyst, hsync_out => href_from_hyst, vsync_out => vsync_from_hyst,
			pixel_data_in => pixel_from_sobel,
			pixel_data_out => pixel_from_hyst
	);

	output_pxclk <= pxclk_from_interface ;
	output_href <= href_from_interface ;
	output_vsync <= vsync_from_interface ;
	output_pixel <= pixel_from_interface ;


	process(sys_clk, sys_resetn)
	begin
		if sys_resetn = '0' then
			vsync_old <= '0' ;
		elsif sys_clk'event and sys_clk = '1' then
			vsync_old <= output_vsync ;
		end if ;
	end process ;
	vsync_rising_edge <= (NOT vsync_old) and output_vsync ;

	process(sys_clk, sys_resetn)
	begin
		if sys_resetn = '0' then
			hsync_old <= '0' ;
		elsif sys_clk'event and sys_clk = '1' then
			hsync_old <= output_href ;
		end if ;
	end process ;
	hsync_rising_edge <= (NOT hsync_old) and output_href ;

	process(sys_clk, sys_resetn)
	begin
		if sys_resetn = '0' then
			pxclk_old <= '0' ;
		elsif sys_clk'event and sys_clk = '1' then
			pxclk_old <= output_pxclk ;
		end if ;
	end process ;
	pxclk_rising_edge <= (NOT pxclk_old) and output_pxclk ;

	process(sys_clk, sys_resetn)
	begin
		if sys_resetn = '0' then
			pixel_buffer(15 downto 0) <= (others => '0') ;
		elsif sys_clk'event and sys_clk = '1' then
			if hsync_rising_edge = '1' then
				pixel_buffer(15 downto 0) <= (others => '0') ;
			elsif pxclk_rising_edge = '1' then
				pixel_buffer(7 downto 0) <= pixel_buffer(15 downto 8) ;
				pixel_buffer(15 downto 8)  <= output_pixel ;
			end if ;
		end if ;
	end process ;

	process(sys_clk, sys_resetn)
	begin
		if sys_resetn = '0' then
			pixel_count <= (others => '0'); 
		elsif sys_clk'event and sys_clk = '1' then
			if hsync_rising_edge = '1' then
				pixel_count <= (others => '0'); 
			elsif pxclk_rising_edge = '1'  and href_from_interface = '0' then
				pixel_count <= pixel_count + 1 ;
			end if ;
		end if ;
	end process ;
	write_pixel <= pixel_count(0);

	process(sys_clk, sys_resetn)
	begin
		if sys_resetn = '0' then
			write_pixel_old <= '0'; 
		elsif sys_clk'event and sys_clk = '1' then
			write_pixel_old <= write_pixel ;
		end if ;
	end process ;


	fifoB_wr <= (write_pixel and (NOT write_pixel_old)) when output_vsync = '0' and output_href = '0' else
				'0' ;
				
	fifo_input <= pixel_buffer ;


--
--	pix2fifo : pixel2fifo 
--	generic map(ADD_SYNC => false)
--	port map(
--		clk => sys_clk, resetn => sys_resetn,
--		pixel_clock => pxclk_from_interface, hsync => href_from_interface, vsync => vsync_from_interface,
--		pixel_data_in => pixel_from_interface,
--		fifo_data => fifo_input, 
--		fifo_wr => fifoB_wr 
--	);



end Behavioral;

