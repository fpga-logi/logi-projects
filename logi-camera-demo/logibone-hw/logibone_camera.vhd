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
use work.peripheral_pack.all ;
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
		PMOD1_9, PMOD1_3  : inout std_logic ; -- used as SCL, SDA
		PMOD1_1 ,PMOD1_4 : out std_logic ; -- used as reset and xclk 
		PMOD1_10, PMOD1_2, PMOD1_8, PMOD1_7 : in std_logic ; -- used as pclk, href, vsync
		PMOD2 : in std_logic_vector(7 downto 0); -- used as cam data
		
		
		--gpmc interface
		GPMC_CSN : in std_logic_vector(2 downto 0);
		GPMC_WEN, GPMC_OEN, GPMC_ADVN, GPMC_CLK, GPMC_BE0N, GPMC_BE1N:	in std_logic;
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

	
	signal clk_sys, clk_100, clk_24, clk_locked : std_logic ;
	signal resetn , sys_resetn : std_logic ;
	
	signal counter_output : std_logic_vector(31 downto 0);
	signal fifo_output : std_logic_vector(15 downto 0);
	signal fifo_input : std_logic_vector(15 downto 0);
	signal latch_output : std_logic_vector(15 downto 0);
	signal fifoB_wr, fifoA_rd, fifoA_rd_old, fifoA_empty, fifoA_full, fifoB_empty, fifoB_full : std_logic ;
	signal bus_data_in, bus_data_out : std_logic_vector(15 downto 0);
	signal bus_fifo_out : std_logic_vector(15 downto 0);
	signal bus_addr : std_logic_vector(15 downto 0);
	signal bus_wr, bus_rd, bus_cs : std_logic ;
	signal cs_fifo : std_logic ;
	
	
	signal cam_data : std_logic_vector(7 downto 0);
	signal cam_sioc, cam_siod : std_logic ;
	signal cam_xclk, cam_pclk, cam_vsync, cam_href, cam_reset : std_logic ;
	
	signal rom_addr : std_logic_vector(7 downto 0);
	signal rom_data : std_logic_vector(15 downto 0);
	
	signal pixel_y_from_interface, pixel_u_from_interface, pixel_v_from_interface: std_logic_vector(7 downto 0);
	signal pxclk_from_interface, href_from_interface, vsync_from_interface : std_logic ;

	
	for all : yuv_register_rom use entity work.yuv_register_rom(ov7725_qvga);
	for all : muxed_addr_interface use entity work.muxed_addr_interface(RTL_v2);
	
begin
	
	resetn <= PB(0) ;
	sys_clocks_gen: clock_gen 
	PORT MAP(
		CLK_IN1 => OSC_FPGA,
		CLK_OUT1 => clk_100,
		CLK_OUT2 => clk_24,
		CLK_OUT3 => clk_sys, --120Mhz system clock
		LOCKED => clk_locked
	);


	reset0: reset_generator 
	generic map(HOLD_0 => 1000)
	port map(clk => clk_sys, 
		resetn => resetn ,
		resetn_0 => sys_resetn
	 );


divider : simple_counter 
	 generic map(NBIT => 32)
    port map( clk => clk_sys, 
           resetn => sys_resetn, 
           sraz => '0',
           en => '1',
			  load => '0' ,
			  E => X"00000000",
			  Q => counter_output
			  );
LED(0) <= counter_output(24);
LED(1) <= cam_vsync ;


mem_interface0 : muxed_addr_interface
generic map(ADDR_WIDTH => 16 , DATA_WIDTH =>  16)
port map(clk => clk_sys ,
	  resetn => sys_resetn ,
	  data	=> GPMC_AD,
	  wrn => GPMC_WEN, oen => GPMC_OEN, addr_en_n => GPMC_ADVN, csn => GPMC_CSN(1),
	  be0n => GPMC_BE0N, be1n => GPMC_BE1N,
	  data_bus_out	=> bus_data_out,
	  data_bus_in	=> bus_data_in ,
	  addr_bus	=> bus_addr, 
	  wr => bus_wr , rd => bus_rd 
);

cs_fifo <= '1' when bus_addr(15 downto 10) = "000000" else
			  '0' ;	  

bus_data_in <= bus_fifo_out when cs_fifo = '1' else
					bus_addr ; --(others => '0');

bi_fifo0 : fifo_peripheral 
		generic map(ADDR_WIDTH => 16,WIDTH => 16, SIZE => 8192, BURST_SIZE => 512)
		port map(
			clk => clk_sys,
			resetn => sys_resetn,
			addr_bus => bus_addr,
			wr_bus => bus_wr,
			rd_bus => bus_rd,
			cs_bus => cs_fifo,
			wrB => fifoB_wr,
			rdA => fifoA_rd,
			data_bus_in => bus_data_out,
			data_bus_out => bus_fifo_out,
			inputB => fifo_input, 
			outputA => fifo_output,
			emptyA => open,
			fullA => open,
			emptyB => open,
			fullB => open,
			burst_available_B => open
		);
 
 conf_rom : yuv_register_rom
	port map(
	   clk => clk_sys, en => '1' ,
 		data => rom_data,
 		addr => rom_addr
	); 
 
 camera_conf_block : i2c_conf 
	generic map(ADD_WIDTH => 8 , SLAVE_ADD => "0100001")
	port map(
		clock => clk_sys, 
		resetn => sys_resetn ,		
 		i2c_clk => clk_24 ,
		scl => PMOD1_9,
 		sda => PMOD1_3, 
		reg_addr => rom_addr ,
		reg_data => rom_data
	);	
		
 camera0: yuv_camera_interface
		port map(clock => clk_sys,
					resetn => sys_resetn,
					pixel_data => cam_data, 
					pxclk => cam_pclk, href => cam_href, vsync => cam_vsync,
					pixel_clock_out => pxclk_from_interface, hsync_out => href_from_interface, vsync_out => vsync_from_interface,
					y_data => pixel_y_from_interface,
					u_data => pixel_u_from_interface,
					v_data => pixel_v_from_interface
		);	
		
	cam_xclk <= clk_24;
	PMOD1_4 <= cam_xclk ;
	--cam_data <= PMOD2 ;
	cam_data <= PMOD2(3) & PMOD2(7) & PMOD2(2) & PMOD2(6) & PMOD2(1) & PMOD2(5) & PMOD2(0) & PMOD2(4) ;
	cam_pclk <= PMOD1_10 ;
	cam_href <= PMOD1_2 ;
	cam_vsync <= PMOD1_8 ;
	PMOD1_1 <= cam_reset ;
	cam_reset <= resetn ;

	
yuv_pix2fifo : yuv_pixel2fifo 
port map(
	clk => clk_sys, resetn => sys_resetn,
	pixel_clock => pxclk_from_interface, hsync => href_from_interface, vsync => vsync_from_interface,
	pixel_y => pixel_y_from_interface,
	pixel_u => pixel_u_from_interface,
	pixel_v => pixel_v_from_interface,
	fifo_data => fifo_input, 
	fifo_wr => fifoB_wr 
);


end Behavioral;

