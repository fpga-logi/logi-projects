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
	signal master_intercon :  wishbone16_bus ;
	signal intercon_fifo0 :  wishbone16_bus ;
	
	
	-- pixel pipeline 
	signal fifo_pixel, sobel_pixel, gauss_pixel, hyst_pixel, output_pixel: y_pixel_bus ;
	
	
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
      wbm_address    => master_intercon.address,  -- Address bus
      wbm_readdata   => master_intercon.readdata,  -- Data bus for read access
      wbm_writedata 	=> master_intercon.writedata,  -- Data bus for write access
      wbm_strobe     => master_intercon.strobe,                      -- Data Strobe
      wbm_write      => master_intercon.write,                      -- Write access
      wbm_ack        => master_intercon.ack,                      -- acknowledge
      wbm_cycle      => master_intercon.cycle                       -- bus cycle in progress
    );


-- Intercon -----------------------------------------------------------
-- will be generated automatically in the future

intercon0 : wishbone_intercon
generic map(memory_map => (0 => "00000XXXXXXXXXXX") -- fifo0
)
port map(
		gls_reset => sys_reset,
		gls_clk   => sys_clk,
		
		
		wbs_address    => master_intercon.address,  	-- Address bus
		wbs_readdata   => master_intercon.readdata,  	-- Data bus for read access
		wbs_writedata 	=> master_intercon.writedata,  -- Data bus for write access
		wbs_strobe     => master_intercon.strobe,     -- Data Strobe
		wbs_write      => master_intercon.write,      -- Write access
		wbs_ack        => master_intercon.ack,        -- acknowledge
		wbs_cycle      => master_intercon.cycle,      -- bus cycle in progress
		
		-- Wishbone master signals
		wbm_address(0) => intercon_fifo0.address,
		wbm_writedata(0)  => intercon_fifo0.writedata,
		wbm_readdata(0)  => intercon_fifo0.readdata,
		wbm_strobe(0)  => intercon_fifo0.strobe,
		wbm_cycle(0)   => intercon_fifo0.cycle,
		wbm_write(0)   => intercon_fifo0.write,
		wbm_ack(0)      => intercon_fifo0.ack
		
);
									      

fifo0 : wishbone_fifo
generic map( ADDR_WIDTH => 16,
			WIDTH	=> 16,
			SIZE	=> 4096,
			BURST_SIZE => 512,
			A_THRESHOLD => 159,
			SYNC_LOGIC_INTERFACE => false 
			)
port map(
	-- Syscon signals
	gls_reset => sys_reset,
	gls_clk   => sys_clk,
	-- Wishbone signals
	wbs_address => intercon_fifo0.address,
	wbs_writedata => intercon_fifo0.writedata,
	wbs_readdata  => intercon_fifo0.readdata,
	wbs_strobe    => intercon_fifo0.strobe,
	wbs_cycle     => intercon_fifo0.cycle,
	wbs_write     => intercon_fifo0.write,
	wbs_ack       => intercon_fifo0.ack,
		  
	-- logic signals  
	write_fifo => fifo_wr, read_fifo => fifo_rd,
	fifo_input => fifo_input,
	fifo_output => fifo_output,
	read_fifo_empty => open, 
	read_fifo_full => open,
	write_fifo_empty => open, 
	write_fifo_full => open,
	write_fifo_threshold => open,
	read_fifo_threshold	=> line_available
);



-- Vision pipeline

pixel_from_fifo : fifo_to_y
	generic map(WIDTH => 320 , HEIGHT => 240)
	port map(
		clk => sys_clk, resetn => sys_resetn ,

		-- fifo side
		line_available => line_available ,
		fifo_rd => fifo_rd ,
		fifo_data =>fifo_output,
		
		-- pixel side 
		pixel_out_data =>  fifo_pixel.data , 
 		pixel_out_clk => fifo_pixel.clk, 
		pixel_out_hsync => fifo_pixel.hsync, 
		pixel_out_vsync =>fifo_pixel.vsync 
	
	);


gaussian_filter : gauss3x3 
generic map(WIDTH => 320, HEIGHT => 240)
port map(
 		clk => sys_clk, 
 		resetn => sys_resetn ,
 		pixel_in_clk => fifo_pixel.clk, 
		pixel_in_hsync => fifo_pixel.hsync, 
		pixel_in_vsync => fifo_pixel.vsync,
 		pixel_out_clk => gauss_pixel.clk, 
		pixel_out_hsync => gauss_pixel.hsync, 
		pixel_out_vsync => gauss_pixel.vsync,
 		pixel_in_data => fifo_pixel.data,
 		pixel_out_data => gauss_pixel.data
);

sobel_filter : sobel3x3 
generic map(WIDTH => 320, HEIGHT => 240)
port map(
 		clk => sys_clk, 
 		resetn => sys_resetn ,
 		pixel_in_clk => gauss_pixel.clk, 
		pixel_in_hsync => gauss_pixel.hsync, 
		pixel_in_vsync => gauss_pixel.vsync,
 		pixel_out_clk => sobel_pixel.clk, 
		pixel_out_hsync => sobel_pixel.hsync, 
		pixel_out_vsync => sobel_pixel.vsync,
 		pixel_in_data => gauss_pixel.data,
 		pixel_out_data => sobel_pixel.data
);

hysteresis : hyst_threshold 
generic map(WIDTH => 320, HEIGHT => 240, LOW_THRESH => 50 , HIGH_THRESH => 90)
port map(
 		clk => sys_clk, 
 		resetn => sys_resetn ,
 		pixel_in_clk => sobel_pixel.clk, 
		pixel_in_hsync => sobel_pixel.hsync, 
		pixel_in_vsync => sobel_pixel.vsync,
 		pixel_out_clk => hyst_pixel.clk, 
		pixel_out_hsync => hyst_pixel.hsync, 
		pixel_out_vsync => hyst_pixel.vsync,
 		pixel_in_data => sobel_pixel.data,
 		pixel_out_data => hyst_pixel.data
);



output_pixel <= sobel_pixel ;


pixel_to_fifo : y_to_fifo
generic map(ADD_SYNC => false)
port map(
	clk => sys_clk, 
	resetn => sys_resetn,
	pixel_in_clk => output_pixel.clk, 
	pixel_in_hsync => output_pixel.hsync, 
	pixel_in_vsync =>  output_pixel.vsync,
	pixel_in_data => output_pixel.data,
	fifo_data => fifo_input,
	fifo_wr => fifo_wr

);
	

LED(0) <= output_pixel.vsync;	
LED(1) <= fifo_wr;	
		  
		  
	 

end Behavioral;

