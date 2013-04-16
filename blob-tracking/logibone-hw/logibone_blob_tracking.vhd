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
use work.blob_pack.all ;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity logibone_blob_tracking is
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
		GPMC_AD :	inout std_logic_vector(15 downto 0)	;
		
		--programming interface
		MODE : in std_logic_vector(1 downto 0);
		INIT : out std_logic
);
end logibone_blob_tracking;

architecture Behavioral of logibone_blob_tracking is

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
	signal image_fifo_wr : std_logic ;
	signal blob_fifo_input : std_logic_vector(15 downto 0);
	signal bus_blob_fifo_out : std_logic_vector(15 downto 0);
	signal blob_fifo_wr, cs_blob_fifo : std_logic ;
	signal bus_data_in, bus_data_out : std_logic_vector(15 downto 0);
	signal bus_fifo_out, bus_latch_out : std_logic_vector(15 downto 0);
	signal latches_data_out : std_logic_vector(15 downto 0);
	signal bus_addr : std_logic_vector(15 downto 0);
	signal bus_wr, bus_rd, bus_cs : std_logic ;
	signal cs_image_fifo, cs_latches : std_logic ;
	
	
	signal cam_data : std_logic_vector(7 downto 0);
	signal cam_sioc, cam_siod : std_logic ;
	signal cam_xclk, cam_pclk, cam_vsync, cam_href, cam_reset : std_logic ;
	
	signal rom_addr : std_logic_vector(7 downto 0);
	signal rom_data : std_logic_vector(15 downto 0);
	
	signal pixel_from_interface : std_logic_vector(7 downto 0);
	signal pxclk_from_interface, href_from_interface, vsync_from_interface : std_logic ;
	signal pixel_from_bin : std_logic_vector(7 downto 0);
	signal pxclk_from_bin, href_from_bin, vsync_from_bin : std_logic ;
	signal pixel_from_erode : std_logic_vector(7 downto 0);
	signal pxclk_from_erode, href_from_erode, vsync_from_erode : std_logic ;
	signal pixel_low_thresh, pixel_high_thresh : std_logic_vector(7 downto 0);
	
	
	signal output_pxclk, output_href , output_vsync : std_logic ;
	signal output_pixel : std_logic_vector(7 downto 0);
	signal hsync_rising_edge, vsync_rising_edge, pxclk_rising_edge, hsync_old, vsync_old, pxclk_old, write_pixel_old : std_logic ;
	signal pixel_buffer : std_logic_vector(15 downto 0);	
	signal pixel_count :std_logic_vector(7 downto 0);
	signal write_pixel : std_logic ;
	
	for all : yuv_register_rom use entity work.yuv_register_rom(ov7725_qvga);
	for all : muxed_addr_interface use entity work.muxed_addr_interface(RTL);
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
--LED(1) <= cam_vsync ;
LED(1) <= pixel_low_thresh(0);

mem_interface0 : muxed_addr_interface
generic map(ADDR_WIDTH => 16 , DATA_WIDTH =>  16)
port map(clk => clk_sys ,
	  resetn => sys_resetn ,
	  data	=> GPMC_AD,
	  wrn => GPMC_WEN, oen => GPMC_OEN, addr_en_n => GPMC_ADVN, csn => GPMC_CSN(1),
	  be0n => GPMC_BE0N, be1n => GPMC_BE1N,
	  --be0n => '1', be1n => '1',
	  data_bus_out	=> bus_data_out,
	  data_bus_in	=> bus_data_in ,
	  addr_bus	=> bus_addr, 
	  wr => bus_wr , rd => bus_rd 
);

cs_image_fifo <= '1' when bus_addr(15 downto 10) = "000000" else
			  '0' ;

cs_blob_fifo <= '1' when bus_addr(15 downto 10) = "000001" else
			  '0' ;
			  
cs_latches <= '1' when bus_addr(15 downto 10) = "000010" else
			  '0' ;

bus_data_in <= bus_fifo_out when cs_image_fifo = '1' else
					bus_blob_fifo_out when cs_blob_fifo = '1' else
					latches_data_out when cs_latches = '1' else
					(others => '1');

bi_fifo0 : fifo_peripheral 
		generic map(ADDR_WIDTH => 16,WIDTH => 16, SIZE => 4096, BURST_SIZE => 512)--16384)
		port map(
			clk => clk_sys,
			resetn => sys_resetn,
			addr_bus => bus_addr,
			wr_bus => bus_wr,
			rd_bus => bus_rd,
			cs_bus => cs_image_fifo,
			wrB => image_fifo_wr,
			rdA => '0',
			data_bus_in => bus_data_out,
			data_bus_out => bus_fifo_out,
			inputB => fifo_input, 
			outputA => open,
			emptyA => open,
			fullA => open,
			emptyB => open,
			fullB => open,
			burst_available_B => open
		);

fifo_blobs : fifo_peripheral 
		generic map(ADDR_WIDTH => 16,
						WIDTH => 16, 
						SIZE => 1024, 
						BURST_SIZE => 512,
						SYNC_LOGIC_INTERFACE => true)
		port map(
			clk => clk_sys,
			resetn => sys_resetn,
			addr_bus => bus_addr,
			wr_bus => bus_wr,
			rd_bus => bus_rd,
			cs_bus => cs_blob_fifo,
			wrB => blob_fifo_wr,
			rdA => '0',
			data_bus_in => bus_data_out,
			data_bus_out => bus_blob_fifo_out,
			inputB => blob_fifo_input, 
			outputA => open,
			emptyA => open,
			fullA => open,
			emptyB => open,
			fullB => open,
			burst_available_B => open
		);		
		
latches0 : latch_peripheral
generic map(ADDR_WIDTH => 16,   WIDTH => 16)
port map(
	clk => clk_sys,
	resetn => sys_resetn,
	addr_bus => bus_addr,
	wr_bus => bus_wr,
	rd_bus => bus_rd,
	cs_bus => cs_latches,
	data_bus_in	=> bus_data_out,
	data_bus_out => latches_data_out,
	latch_input => pixel_high_thresh  & pixel_low_thresh,
	latch_output(15 downto 8) => pixel_high_thresh ,
	latch_output(7 downto 0) => pixel_low_thresh
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
					y_data => pixel_from_interface
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

binarization0 : synced_binarization
port map( 		clk => clk_sys, 
 		resetn => sys_resetn ,
 		pixel_clock => pxclk_from_interface, hsync => href_from_interface, vsync => vsync_from_interface,
 		pixel_clock_out => pxclk_from_bin, hsync_out => href_from_bin, vsync_out => vsync_from_bin,
		pixel_data_1 => pixel_from_interface,
		pixel_data_2 => x"0F",
		pixel_data_3 => x"0F",
		upper_bound_1	=> pixel_low_thresh,
		upper_bound_2	=> x"FF",
		upper_bound_3	=> x"FF",
		lower_bound_1	=> pixel_high_thresh,
		lower_bound_2	=>x"00",
		lower_bound_3	=>x"00",
		pixel_data_out => pixel_from_bin
);


erode0 : erode3x3 
generic map(WIDTH => 320, HEIGHT => 240)
port map(
 		clk => clk_sys, 
 		resetn => sys_resetn ,
 		pixel_clock => pxclk_from_bin, hsync => href_from_bin, vsync => vsync_from_bin,
 		pixel_clock_out => pxclk_from_erode, hsync_out => href_from_erode, vsync_out => vsync_from_erode,
 		pixel_data_in => pixel_from_bin,
 		pixel_data_out => pixel_from_erode
);


blob_tracker : blob_detection 
generic map(LINE_SIZE => 320)
port map(
 		clk => clk_sys, 
 		resetn => sys_resetn ,
 		pixel_clock => pxclk_from_erode, hsync => href_from_erode, vsync => vsync_from_erode,
		pixel_data_in => pixel_from_erode,
		blob_data => open,
		
		--memory_interface to copy results on vsync
		mem_addr => open,
		mem_data =>blob_fifo_input,
		mem_wr => blob_fifo_wr
);





output_pxclk <= pxclk_from_erode ;
output_href <= href_from_erode ;
output_vsync <= vsync_from_erode ;
output_pixel <= pixel_from_erode ;




--output_pxclk <= pxclk_from_interface ;
--output_href <= href_from_interface ;
--output_vsync <= vsync_from_interface ;
--output_pixel <= pixel_from_interface ;
	
--pix2fifo : pixel2fifo 
--port map(
--	clk => clk_sys, resetn => sys_resetn,
--	pixel_clock => output_pxclk, hsync => output_href, vsync => output_vsync,
--	pixel_data_in => output_pixel,
--	fifo_data => fifo_input, 
--	fifo_wr => image_fifo_wr 
--
--);


	
	process(clk_sys, sys_resetn)
begin
	if sys_resetn = '0' then
		vsync_old <= '0' ;
	elsif clk_sys'event and clk_sys = '1' then
		vsync_old <= output_vsync ;
	end if ;
end process ;
vsync_rising_edge <= (NOT vsync_old) and output_vsync ;

process(clk_sys, sys_resetn)
begin
	if sys_resetn = '0' then
		hsync_old <= '0' ;
	elsif clk_sys'event and clk_sys = '1' then
		hsync_old <= output_href ;
	end if ;
end process ;
hsync_rising_edge <= (NOT hsync_old) and output_href ;

process(clk_sys, sys_resetn)
begin
	if sys_resetn = '0' then
		pxclk_old <= '0' ;
	elsif clk_sys'event and clk_sys = '1' then
		pxclk_old <= output_pxclk ;
	end if ;
end process ;
pxclk_rising_edge <= (NOT pxclk_old) and output_pxclk ;

process(clk_sys, sys_resetn)
begin
	if sys_resetn = '0' then
		pixel_buffer(15 downto 0) <= (others => '0') ;
	elsif clk_sys'event and clk_sys = '1' then
		if hsync_rising_edge = '1' then
			pixel_buffer(15 downto 0) <= (others => '0') ;
		elsif pxclk_rising_edge = '1' then
			pixel_buffer(7 downto 0) <= pixel_buffer(15 downto 8) ;
			pixel_buffer(15 downto 8)  <= output_pixel ;
		end if ;
	end if ;
end process ;

process(clk_sys, sys_resetn)
begin
	if sys_resetn = '0' then
		pixel_count <= (others => '0'); 
	elsif clk_sys'event and clk_sys = '1' then
		if hsync_rising_edge = '1' then
			pixel_count <= (others => '0'); 
		elsif pxclk_rising_edge = '1'  and href_from_interface = '0' then
			pixel_count <= pixel_count + 1 ;
		end if ;
	end if ;
end process ;
write_pixel <= pixel_count(0);

process(clk_sys, sys_resetn)
begin
	if sys_resetn = '0' then
		write_pixel_old <= '0'; 
	elsif clk_sys'event and clk_sys = '1' then
		write_pixel_old <= write_pixel ;
	end if ;
end process ;


image_fifo_wr <= (write_pixel and (NOT write_pixel_old)) when output_vsync = '0' and output_href = '0' else
			   vsync_rising_edge when output_vsync = '1' else
				'0' ;
				
fifo_input <= (X"AA55") when vsync_rising_edge = '1' else
				  (pixel_buffer(15 downto 1) & '0') when pixel_buffer = X"AA55" else
				  pixel_buffer;

INIT <= '1' ;

end Behavioral;

