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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

library work ;
use work.utils_pack.all ;
use work.logi_wishbone_pack.all ;
use work.logi_wishbone_peripherals_pack.all ;
use work.interface_pack.all ;
use work.conf_pack.all ;
use work.filter_pack.all ;
use work.feature_pack.all ;
use work.image_pack.all ;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity logibone_camera is
port( OSC_FPGA : in std_logic;
		PB, SW : in std_logic_vector(1 downto 0);
		LED : out std_logic_vector(1 downto 0);
		
		--PMOD
		PMOD1 : inout std_logic_vector(7 downto 0); -- used as cam ctrl
		PMOD2 : inout std_logic_vector(7 downto 0); -- used as cam data
		
		-- i2C
		ARD_SDA, ARD_SCL : inout std_logic ;
		
		--gpmc interface
		GPMC_CSN : in std_logic;
		GPMC_WEN, GPMC_OEN, GPMC_ADVN, GPMC_CLK :	in std_logic;
		GPMC_BEN : in std_logic_vector(1 downto 0);
		GPMC_AD :	inout std_logic_vector(15 downto 0)
);
end logibone_camera;

architecture Behavioral of logibone_camera is

	COMPONENT clock_gen
	PORT(
		CLK_IN1 : IN std_logic;          
		CLK_OUT1 : OUT std_logic;
		CLK_OUT2 : OUT std_logic;
		LOCKED : OUT std_logic
		);
	END COMPONENT;

	
	signal gls_clk, clk_120, clk_24, clk_locked : std_logic ;
	signal gls_reset , gls_resetn : std_logic ;
	
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
	
	
	
	signal cam_data : std_logic_vector(7 downto 0);
	signal cam_sioc, cam_siod : std_logic ;
	signal cam_xclk, cam_pclk, cam_vsync, cam_href, cam_reset : std_logic ;
	
	signal rom_addr : std_logic_vector(7 downto 0);
	signal rom_data : std_logic_vector(15 downto 0);
	
	signal pixel_y_from_interface, pixel_u_from_interface, pixel_v_from_interface: std_logic_vector(7 downto 0);
	signal pxclk_from_interface, href_from_interface, vsync_from_interface : std_logic ;

	signal pixel_from_harris : std_logic_vector(7 downto 0);
	signal harris_resp : std_logic_vector(15 downto 0);
	signal signed_harris_resp : signed(15 downto 0);
	signal pxclk_from_harris, href_from_harris, vsync_from_harris : std_logic ;
	signal pixel_from_gauss: std_logic_vector(7 downto 0);
	signal pxclk_from_gauss, href_from_gauss, vsync_from_gauss : std_logic ;
	signal pixel_from_sobel: std_logic_vector(7 downto 0);
	signal pxclk_from_sobel, href_from_sobel, vsync_from_sobel : std_logic ;
	signal pixel_from_switch: std_logic_vector(7 downto 0);
	signal pxclk_from_switch, href_from_switch, vsync_from_switch : std_logic ;
	signal pixel_from_classifier: std_logic_vector(7 downto 0);
	signal pxclk_from_classifier, href_from_classifier, vsync_from_classifier : std_logic ;
	
	signal chist_reset, chist_available : std_logic ;
	signal chist_pixel_val : std_logic_vector(7 downto 0);
	signal chist_val_amount : std_logic_vector(31 downto 0);
	
	signal switch_value : std_logic_vector(1 downto 0);

	signal preview_fifo_wr : std_logic ;
	signal preview_fifo_input : std_logic_vector(15 downto 0);
	signal reset_pipeline : std_logic ;
	signal cam_conf_reset : std_logic ;	
	for all : yuv_register_rom use entity work.yuv_register_rom(ov7670_qvga);
	for all : gauss3x3 use entity work.gauss3x3(RTL);
	for all : sobel3x3 use entity work.sobel3x3(RTL);
	constant IMAGE_WIDTH : integer := 320 ;
	constant IMAGE_HEIGHT : integer := 240 ;
	
begin
	
	
	ARD_SCL <= 'Z' ;
	ARD_SDA <= 'Z' ;
	
	
	sys_clocks_gen: clock_gen 
	PORT MAP(
		CLK_IN1 => OSC_FPGA,
		CLK_OUT1 => gls_clk,
		CLK_OUT2 => clk_24,
		LOCKED => clk_locked
	);

	gls_reset <= not clk_locked ;
	gls_resetn <= not gls_reset ;

	LED(1) <= cam_vsync ;
	LED(0) <= gls_reset ;

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
      gls_reset => gls_reset,
      gls_clk   => gls_clk,
      -- Wishbone interface signals
      wbm_address    => intercon_wrapper_wbm_address,  -- Address bus
      wbm_readdata   => intercon_wrapper_wbm_readdata,  -- Data bus for read access
      wbm_writedata 	=> intercon_wrapper_wbm_writedata,  -- Data bus for write access
      wbm_strobe     => intercon_wrapper_wbm_strobe,     -- Data Strobe
      wbm_write      => intercon_wrapper_wbm_write,      -- Write access
      wbm_ack        => intercon_wrapper_wbm_ack,        -- acknowledge
      wbm_cycle      => intercon_wrapper_wbm_cycle       -- bus cycle in progress
    );


intercon0 : wishbone_intercon
generic map(memory_map => (0 => "000000XXXXXXXXXX") -- fifo0
)
port map(
		gls_reset => gls_reset,
			gls_clk   => gls_clk,
		
		
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


bi_fifo0 : wishbone_fifo 
		generic map(
			ADDR_WIDTH => 16,
			WIDTH => 16, 
			SIZE => 8192, 
			B_BURST_SIZE => 512,
			SYNC_LOGIC_INTERFACE => true)
		port map(
			gls_clk => gls_clk,
			gls_reset => gls_reset,

			wbs_address  => intercon_fifo0_wbm_address , 
			wbs_writedata => intercon_fifo0_wbm_writedata,
			wbs_readdata  => intercon_fifo0_wbm_readdata,
			wbs_strobe   => intercon_fifo0_wbm_strobe,
			wbs_cycle    => intercon_fifo0_wbm_cycle,
			wbs_write    => intercon_fifo0_wbm_write,
			wbs_ack      => intercon_fifo0_wbm_ack,
			
			
		-- logic signals  
		wrB => preview_fifo_wr, rdA => '0',
		inputB => preview_fifo_input,
		outputA => open,
		emptyA => open, 
		fullA => open,
		emptyB => open, 
		fullB => open,
		burst_available_B => open,
		burst_available_A	=> open,
		fifoB_reset => reset_pipeline
		);
 
 conf_rom : yuv_register_rom
	port map(
	   clk => gls_clk, en => '1' ,
 		data => rom_data,
 		addr => rom_addr
	); 
 
 camera_conf_block : i2c_conf 
	generic map(ADD_WIDTH => 8 , SLAVE_ADD => "0100001")
	port map(
		clock => clk_24, 
		resetn => gls_resetn ,		
 		i2c_clk => clk_24 ,
		scl => PMOD2(6),
 		sda => PMOD2(2), 
		reg_addr => rom_addr ,
		reg_data => rom_data
	);	
		
 camera0: yuv_camera_interface
		port map(clock => gls_clk,
					resetn => gls_resetn,
					pixel_data => cam_data, 
					pxclk => cam_pclk, href => cam_href, vsync => cam_vsync,
					pixel_clock_out => pxclk_from_interface, hsync_out => href_from_interface, vsync_out => vsync_from_interface,
					y_data => pixel_y_from_interface,
					u_data => pixel_u_from_interface,
					v_data => pixel_v_from_interface
		);	
		
	cam_xclk <= clk_24;
	PMOD2(3) <= cam_xclk ;
	cam_data <= PMOD1(3) & PMOD1(7) & PMOD1(2) & PMOD1(6) & PMOD1(1) & PMOD1(5) & PMOD1(0) & PMOD1(4) ;
	cam_pclk <= PMOD2(7) ;
	cam_href <= PMOD2(1) ;
	cam_vsync <= PMOD2(5) ;
	PMOD2(0) <= cam_reset ;
	cam_reset <= gls_resetn ;


	
	gauss3x3_0	: gauss3x3 
		generic map(WIDTH => IMAGE_WIDTH,
				  HEIGHT => IMAGE_HEIGHT)
		port map(
					clk => gls_clk ,
					resetn => gls_resetn ,
					pixel_clock => pxclk_from_interface, 
					hsync => href_from_interface, 
					vsync =>  vsync_from_interface,
					pixel_clock_out => pxclk_from_gauss, 
					hsync_out => href_from_gauss, 
					vsync_out => vsync_from_gauss, 
					pixel_data_in => pixel_y_from_interface,  
					pixel_data_out => pixel_from_gauss
		);		
		
	
	sobel0: sobel3x3
		generic map(WIDTH => IMAGE_WIDTH,
				  HEIGHT => IMAGE_HEIGHT)
		port map(
			clk => gls_clk ,
			resetn => gls_resetn ,
			pixel_clock => pxclk_from_gauss, hsync => href_from_gauss, vsync =>  vsync_from_gauss,
			pixel_clock_out => pxclk_from_sobel, hsync_out => href_from_sobel, vsync_out => vsync_from_sobel, 
			pixel_data_in => pixel_from_gauss,  
			pixel_data_out => pixel_from_sobel
		);	


	harris_detector : HARRIS 
	generic map(WIDTH => IMAGE_WIDTH, HEIGHT => IMAGE_HEIGHT, WINDOW_SIZE => 5, DS_FACTOR => 2)
	port map(
			clk => gls_clk,
			resetn => gls_resetn, 
			pixel_clock => pxclk_from_interface, 
			hsync => href_from_interface,
			vsync => vsync_from_interface, 
			pixel_clock_out =>pxclk_from_harris,
			hsync_out => href_from_harris, 
			vsync_out => vsync_from_harris,
			pixel_data_in =>  pixel_y_from_interface,
			harris_out => harris_resp 
	);
	signed_harris_resp <= signed(harris_resp) ;

	pixel_from_harris <=  (others => '0') when harris_resp(15) = '1' else
								  harris_resp(7 downto 0) when signed_harris_resp < 256 else
								  (others => '1');
								  
								  
								  



		video_switch_inst: video_switch
		generic map(NB	=>  4)
		port map(
			pixel_clock(0) => pxclk_from_interface, 
			pixel_clock(1) => pxclk_from_gauss, 
			pixel_clock(2) => pxclk_from_sobel, 
			pixel_clock(3) => pxclk_from_harris,

			hsync(0) => href_from_interface,
			hsync(1) => href_from_gauss, 
			hsync(2) => href_from_sobel,
			hsync(3) => href_from_harris,


			vsync(0) => vsync_from_interface,
			vsync(1) => vsync_from_gauss,
			vsync(2) => vsync_from_sobel,
			vsync(3) => vsync_from_harris,

			pixel_data(0) => pixel_y_from_interface	,
			pixel_data(1) => pixel_from_gauss	,
			pixel_data(2) => pixel_from_sobel	,
			pixel_data(3) => pixel_from_harris	,


			pixel_clock_out => pxclk_from_switch, 
			hsync_out => href_from_switch, 
			vsync_out => vsync_from_switch,
			pixel_data_out => pixel_from_switch,
			channel(1 downto 0) => switch_value(1 downto 0),
			channel(7 downto 2) => "000000"
		);
		switch_value <= SW ;
	

	pixel_to_fifo : yuv_pixel2fifo
		port map(
			clk => gls_clk, resetn => gls_resetn,
			sreset => reset_pipeline , -- should wire to a register to allow to reset 
			pixel_clock => pxclk_from_switch, 
			hsync => href_from_switch, 
			vsync => vsync_from_switch,
			pixel_y => pixel_from_switch,
			pixel_u => X"80",
			pixel_v => X"80",
			fifo_data => preview_fifo_input,
			fifo_wr => preview_fifo_wr
		);	



end Behavioral;

