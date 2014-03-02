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
use work.image_pack.all ;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity logibone_camera is
port( OSC_FPGA : in std_logic;
		PB : in std_logic_vector(1 downto 0);
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
		CLK_OUT3 : OUT std_logic;
		LOCKED : OUT std_logic
		);
	END COMPONENT;

	
	signal gls_clk, clk_120, clk_24, clk_locked : std_logic ;
	signal gls_reset , sys_resetn : std_logic ;
	
	signal counter_output : std_logic_vector(31 downto 0);
	signal fifo_output : std_logic_vector(15 downto 0);
	signal fifo_input : std_logic_vector(15 downto 0);
	signal latch_output : std_logic_vector(15 downto 0);
	signal fifoB_wr, fifoA_rd, fifoA_rd_old, fifoA_empty, fifoA_full, fifoB_empty, fifoB_full : std_logic ;
	
	
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

	signal pipeline_reset : std_logic ;
	
	for all : yuv_register_rom use entity work.yuv_register_rom(ov7725_qvga);
	
begin
	
	
	ARD_SCL <= 'Z' ;
	ARD_SDA <= 'Z' ;
	
	
	sys_clocks_gen: clock_gen 
	PORT MAP(
		CLK_IN1 => OSC_FPGA,
		CLK_OUT1 => gls_clk,
		CLK_OUT2 => clk_24,
		CLK_OUT3 => clk_120, --120Mhz system clock
		LOCKED => clk_locked
	);


rst_gen : reset_generator -- camera needs a 1ms reset before taking commands
generic map(HOLD_0	=> 5000)
port map(clk => gls_clk, 
	  resetn => PB(0),
     resetn_0 => sys_resetn
	  );

gls_reset <= NOT sys_resetn; 

LED(1) <= cam_vsync ;
LED(0) <= gls_reset ;

gpmc2wishbone : gpmc_wishbone_wrapper 
generic map(sync => true, burst => true)
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
			
			
			wrB => fifoB_wr,
			rdA => fifoA_rd,
			inputB => fifo_input, 
			outputA => fifo_output,
			emptyA => open,
			fullA => open,
			emptyB => open,
			fullB => open,
			burst_available_B => open,
			fifoB_reset => pipeline_reset
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
		clock => gls_clk, 
		resetn => sys_resetn ,		
 		i2c_clk => clk_24 ,
		scl => PMOD2(6),
 		sda => PMOD2(2), 
		reg_addr => rom_addr ,
		reg_data => rom_data
	);	
		
 camera0: yuv_camera_interface
		port map(clock => gls_clk,
					resetn => sys_resetn,
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
	cam_reset <= PB(0) ;

	
--yuv_pix2fifo : yuv_pixel2fifo 
--port map(
--	clk => gls_clk, resetn => sys_resetn,
--	sreset => pipeline_reset ,
--	pixel_clock => pxclk_from_interface, hsync => href_from_interface, vsync => vsync_from_interface,
--	pixel_y => pixel_y_from_interface,
--	pixel_u => pixel_u_from_interface,
--	pixel_v => pixel_v_from_interface,
--	fifo_data => fifo_input, 
--	fifo_wr => fifoB_wr 
--);


adapt_bin : adaptive_pixel_class
		generic map(nb_class => 2)
		port map(
			clk => clk,
			resetn => resetn,
			pixel_clock => pxclk_from_interface,
			hsync => hsync,
			vsync => vsync,
			pixel_data_in => pixel_data_in,
			pixel_clock_out => class_pxclk_out, 
			hsync_out => class_hsync_out, 
			vsync_out => class_vsync_out,
			pixel_data_out => pixel_class_out,
			chist_addr => chist_pixel_val,
			chist_data => chist_val_amount,
			chist_available => chist_available ,
			chist_reset => reset_chist_run 
		);


pix_to_fifo : pixel2fifo 
generic map(ADD_SYNC => true)
port map(
	clk => gls_clk, resetn => sys_resetn,
--	sreset => pipeline_reset ,
	pixel_clock => pxclk_from_interface, hsync => href_from_interface, vsync => vsync_from_interface,
	pixel_data_in => pixel_y_from_interface,
	--pixel_y => pixel_y_from_interface,
	--pixel_u => pixel_u_from_interface,
	--pixel_v => pixel_v_from_interface,
	fifo_data => fifo_input, 
	fifo_wr => fifoB_wr 
);



end Behavioral;

