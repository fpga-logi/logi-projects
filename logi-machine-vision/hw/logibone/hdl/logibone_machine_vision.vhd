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
library UNISIM;
use UNISIM.VComponents.all;

library work ;
use work.logi_wishbone_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;
use work.filter_pack.all ;
use work.image_pack.all ;

entity logibone_machine_vision is
port( OSC_FPGA : in std_logic;
		PB : in std_logic_vector(1 downto 0);
		SW : in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(1 downto 0);	
		
		-- I2C
			
		ARD_SCL, ARD_SDA : inout std_logic ;
		
		--gpmc interface
		GPMC_CSN : in std_logic ;
		GPMC_BEN:	in std_logic_vector(1 downto 0);
		GPMC_WEN, GPMC_OEN, GPMC_ADVN :	in std_logic;
		GPMC_CLK :	in std_logic;
		GPMC_AD :	inout std_logic_vector(15 downto 0)	
);
end logibone_machine_vision;

architecture Behavioral of logibone_machine_vision is

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
	signal sys_reset, sys_resetn,sys_clk, clock_locked : std_logic ;
	signal clk_100Mhz, clk_120Mhz, clk_20Mhz, clk_50Mhz, clk_50Mhz_ext : std_logic ;

	-- wishbone intercon signals
	signal intercon_wrapper_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_wrapper_wbm_strobe :  std_logic;
	signal intercon_wrapper_wbm_write :  std_logic;
	signal intercon_wrapper_wbm_ack :  std_logic;
	signal intercon_wrapper_wbm_cycle :  std_logic;
	
	signal intercon_fifo0_wbm_address :  std_logic_vector(15 downto 0);
	signal intercon_fifo0_wbm_readdata :  std_logic_vector(15 downto 0);
	signal intercon_fifo0_wbm_writedata :  std_logic_vector(15 downto 0);
	signal intercon_fifo0_wbm_strobe :  std_logic;
	signal intercon_fifo0_wbm_write :  std_logic;
	signal intercon_fifo0_wbm_ack :  std_logic;
	signal intercon_fifo0_wbm_cycle :  std_logic;
	
	signal fifo0_cs : std_logic ;
	
	-- pixel pipeline 
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
	
	signal fifo_wr, fifo_rd, line_available : std_logic ;
	signal fifo_input, fifo_output : std_logic_vector(15 downto 0);
	
	
	for all : sobel3x3 use entity work.sobel3x3(RTL) ;
	for all : gauss3x3 use entity work.gauss3x3(RTL) ;
	
begin

--LED(1) <= (GPMC_BEN(0) XOR GPMC_BEN(1)) ;

sys_reset <= NOT PB(0); 
sys_resetn <= NOT sys_reset ; -- for preipherals with active low reset

pll0 : clock_gen
  port map
   (-- Clock in ports
    CLK_IN1 => OSC_FPGA,
    -- Clock out ports
    CLK_OUT1 => clk_100Mhz,
	 CLK_OUT2 => clk_20Mhz,
    -- Status and control signals
    LOCKED => clock_locked);

sys_clk <= clk_100Mhz;


gpmc2wishbone : gpmc_wishbone_wrapper 
generic map(sync => true, burst => false)
port map
    (
      -- GPMC SIGNALS
      gpmc_ad => GPMC_AD, 
      gpmc_csn => GPMC_CSN,
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

intercon0 : wishbone_intercon
generic map(memory_map => (0 => "00000XXXXXXXXXXX") -- fifo0
)
port map(
		gls_reset => sys_reset,
		gls_clk   => sys_clk,
		
		
		wbs_address    => intercon_wrapper_wbm_address,  	-- Address bus
		wbs_readdata   => intercon_wrapper_wbm_readdata,  	-- Data bus for read access
		wbs_writedata 	=> intercon_wrapper_wbm_writedata,  -- Data bus for write access
		wbs_strobe     => intercon_wrapper_wbm_strobe,     -- Data Strobe
		wbs_write      => intercon_wrapper_wbm_write,      -- Write access
		wbs_ack        => intercon_wrapper_wbm_ack,        -- acknowledge
		wbs_cycle      => intercon_wrapper_wbm_cycle,      -- bus cycle in progress
		
		-- Wishbone master signals
		wbm_address(0) => intercon_fifo0_wbm_address,
		wbm_writedata(0)  => intercon_fifo0_wbm_writedata,
		wbm_readdata(0)  => intercon_fifo0_wbm_readdata,
		wbm_strobe(0)  => intercon_fifo0_wbm_strobe,
		wbm_cycle(0)   => intercon_fifo0_wbm_cycle,
		wbm_write(0)   => intercon_fifo0_wbm_write,
		wbm_ack(0)      => intercon_fifo0_wbm_ack
		
);
									      

fifo0 : wishbone_fifo
generic map( ADDR_WIDTH => 16,
			WIDTH	=> 16,
			SIZE	=> 4096,
			B_BURST_SIZE => 512,
			A_BURST_SIZE => 159,
			SYNC_LOGIC_INTERFACE => false 
			)
port map(
	-- Syscon signals
	gls_reset => sys_reset,
	gls_clk   => sys_clk,
	-- Wishbone signals
	wbs_address => intercon_fifo0_wbm_address,
	wbs_writedata => intercon_fifo0_wbm_writedata,
	wbs_readdata  => intercon_fifo0_wbm_readdata,
	wbs_strobe    => intercon_fifo0_wbm_strobe,
	wbs_cycle     => intercon_fifo0_wbm_cycle,
	wbs_write     => intercon_fifo0_wbm_write,
	wbs_ack       => intercon_fifo0_wbm_ack,
		  
	-- logic signals  
	wrB => fifo_wr, rdA => fifo_rd,
	inputB => fifo_input,
	outputA => fifo_output,
	emptyA => open, 
	fullA => open,
	emptyB => open, 
	fullB => open,
	burst_available_B => open,
	burst_available_A	=> line_available
);



-- Vision pipeline

pixel_from_fifo : fifo2pixel
	generic map(WIDTH => 320 , HEIGHT => 240)
	port map(
		clk => sys_clk, resetn => sys_resetn ,

		-- fifo side
		line_available => line_available ,
		fifo_rd => fifo_rd ,
		fifo_data =>fifo_output,
		
		-- pixel side 
		y_data =>  pixel_from_interface , 
 		pixel_clock_out => pxclk_from_interface, 
		hsync_out => href_from_interface, 
		vsync_out =>vsync_from_interface 
	
	);
--fifo_rd <= '0' ;
--fifo_wr <= '0' ;
	
--fifo_input <= X"00" & pixel_from_interface;	
--fifo_wr <= pxclk_from_interface and (not href_from_interface);

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
 		resetn => sys_resetn ,
 		pixel_clock => pxclk_from_sobel, hsync => href_from_sobel, vsync => vsync_from_sobel,
 		pixel_clock_out => pxclk_from_hyst, hsync_out => href_from_hyst, vsync_out => vsync_from_hyst,
 		pixel_data_in => pixel_from_sobel,
 		pixel_data_out => pixel_from_hyst
);


--output_pxclk <= pxclk_from_hyst ;
--output_href <= href_from_hyst ;
--output_vsync <= vsync_from_hyst ;
--output_pixel <= pixel_from_hyst ;

output_pxclk <= pxclk_from_sobel ;
output_href <= href_from_sobel ;
output_vsync <= vsync_from_sobel ;
output_pixel <= pixel_from_sobel ;

--output_pxclk <= pxclk_from_gauss ;
--output_href <= href_from_gauss ;
--output_vsync <= vsync_from_gauss ;
--output_pixel <= pixel_from_gauss ;
--
--output_pxclk <= pxclk_from_interface ;
--output_href <= href_from_interface ;
--output_vsync <= vsync_from_interface ;
--output_pixel <= pixel_from_interface ;
--output_pixel <= X"FF" ;	

pixel_to_fifo : pixel2fifo
generic map(ADD_SYNC => false)
port map(
	clk => sys_clk, resetn => sys_resetn,
	pixel_clock => output_pxclk, hsync => output_href, vsync =>  output_vsync,
	pixel_data_in => output_pixel,
	fifo_data => fifo_input,
	fifo_wr => fifo_wr

);
	

LED(0) <= output_vsync;	
LED(1) <= fifo_wr;	
		  
		  
	 

end Behavioral;

