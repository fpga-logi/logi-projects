----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:28:56 07/06/2014 
-- Design Name: 
-- Module Name:    wishbone_led_matrix_ctrl - Behavioral 
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

----------------------------------------------------------------------------------
-- This controller is based on Glen Atkins work (http://bikerglen.com/projects/lighting/led-panel-1up/)
-- Minor modification on controller behavior to adapt to wishbone bus
-- Major modification on coding style to meet XST guidelines
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
library work;
use work.logi_utils_pack.all ;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wishbone_led_matrix_ctrl is
generic(wb_size : positive := 16;
		  clk_div : positive := 10;
		  -- TODO: nb_panels is untested, still need to be validated
		  nb_panels : positive := 1 ;
		  expose_step : positive := 191 
		  );
port(
		  -- Syscon signals
		  gls_reset    : in std_logic ;
		  gls_clk      : in std_logic ;
		  -- Wishbone signals
		  wbs_address       : in std_logic_vector(15 downto 0) ;
		  wbs_writedata : in std_logic_vector( wb_size-1 downto 0);
		  wbs_readdata  : out std_logic_vector( wb_size-1 downto 0);
		  wbs_strobe    : in std_logic ;
		  wbs_cycle      : in std_logic ;
		  wbs_write     : in std_logic ;
		  wbs_ack       : out std_logic;
		  
		  
		  SCLK_OUT : out std_logic ;
		  BLANK_OUT : out std_logic ;
		  LATCH_OUT : out std_logic ;
		  A_OUT : out std_logic_vector(3 downto 0);
		  R_out : out std_logic_vector(1 downto 0);
		  G_out : out std_logic_vector(1 downto 0);
		  B_out : out std_logic_vector(1 downto 0)

);
end wishbone_led_matrix_ctrl;

architecture Behavioral of wishbone_led_matrix_ctrl is

component dpram_NxN is
	generic(SIZE : natural := 64 ; NBIT : natural := 8; ADDR_WIDTH : natural := 6);
	port(
 		clk : in std_logic; 
 		we : in std_logic; 
 		
 		di : in std_logic_vector(NBIT-1 downto 0 ); 
		a	:	in std_logic_vector((ADDR_WIDTH - 1) downto 0 );
 		dpra : in std_logic_vector((ADDR_WIDTH - 1) downto 0 );
		spo : out std_logic_vector(NBIT-1 downto 0 );
		dpo : out std_logic_vector(NBIT-1 downto 0 ) 		
	); 
end component;


type ctrl_state is (EXPOSE, BLANK, LATCH, UNBLANK, READ, SHIFT1, SHIFT2);

constant LINE_SIZE : positive := 32*nb_panels ;
constant RAM_SIZE : positive := LINE_SIZE*32 ;

signal cur_state, next_state : ctrl_state ;
signal read_ack : std_logic ;
signal write_ack, write_mem0, write_mem1 : std_logic ;


signal next_pixel_div, bin_code_delay : std_logic_vector(15 downto 0);
signal end_count : std_logic ;
signal col_count : std_logic_vector(nbit(LINE_SIZE)-1 downto 0);
signal line_count : std_logic_vector(3 downto 0);
signal clk_count, count_load_val : std_logic_vector(15 downto 0) ;
signal rd_bit, exp_bit : std_logic_vector(1 downto 0);
signal pixel_addr : std_logic_vector(8 downto 0);
signal line_count_enable, col_count_enable, rd_bit_count_enable : std_logic ;
signal line_count_reset, col_count_reset : std_logic ;


signal pixel_data_line0, pixel_data_line16 : std_logic_vector(15 downto 0);

signal end_of_col, rd_bit_3 : std_logic ;
signal shift_count : std_logic_vector(3 downto 0);

signal SCLK_Q, LATCH_Q, BLANK_Q : std_logic ;
signal R1_Q, G1_Q, B1_Q, R0_Q, G0_Q, B0_Q : std_logic ;
signal A_OUT_Q : std_logic_vector(3 downto 0);
begin


-- wishbone related logic

wbs_ack <= read_ack or write_ack;

write_bloc : process(gls_clk,gls_reset)
begin
    if gls_reset = '1' then 
        write_ack <= '0';
    elsif rising_edge(gls_clk) then
        if ((wbs_strobe and wbs_write and wbs_cycle) = '1' ) then
            write_ack <= '1';
        else
            write_ack <= '0';
        end if;
    end if;
end process write_bloc;


read_bloc : process(gls_clk, gls_reset)
begin
    if gls_reset = '1' then
        
    elsif rising_edge(gls_clk) then
        if (wbs_strobe = '1' and wbs_write = '0'  and wbs_cycle = '1' ) then
            read_ack <= '1';
        else
            read_ack <= '0';
        end if;
    end if;
end process read_bloc;

wbs_readdata <= X"DEAD" ;


-- ram buffer instanciation

write_mem0  <= wbs_strobe and wbs_write and wbs_cycle and (not wbs_address(9))  ;
frame_buffer0 : dpram_NxN 
	generic map(SIZE  => RAM_SIZE/2,  NBIT => 16, ADDR_WIDTH => nbit(RAM_SIZE/2))
	port map(
 		clk => gls_clk,
 		we => write_mem0, 
 		
 		di => wbs_writedata, 
		a	=> wbs_address(nbit(RAM_SIZE/2)-1 downto 0) ,
 		dpra => pixel_addr, 
		spo => open,
		dpo => pixel_data_line0
	);
	
	
write_mem1  <= wbs_strobe and wbs_write and wbs_cycle and wbs_address(9)  ;
frame_buffer1 : dpram_NxN 
	generic map(SIZE  => RAM_SIZE/2,  NBIT => 16, ADDR_WIDTH => nbit(RAM_SIZE/2))
	port map(
 		clk => gls_clk,
 		we => write_mem1, 
 		
 		di => wbs_writedata, 
		a	=> wbs_address(nbit(RAM_SIZE/2)-1 downto 0) ,
 		dpra => pixel_addr, 
		spo => open,
		dpo => pixel_data_line16	
	); 


-- ram buffer read address decoding
pixel_addr <= line_count & col_count ;



-- state machine code

-- state machine latch state process
process(gls_clk, gls_reset)
begin
    if gls_reset = '1' then
        cur_state <= EXPOSE ;
    elsif rising_edge(gls_clk) then
       cur_state <= next_state ;
    end if;
end process;


-- state machine, state evolution process				 
process(cur_state, end_count, col_count, end_of_col)
begin
    next_state <= cur_state ;
	 case cur_state is 
	   when EXPOSE =>
			if end_count = '1' then
				next_state <= BLANK ;
			end if ;
		when BLANK =>
			if end_count = '1' then
				next_state <= LATCH ;
			end if ;
		when LATCH =>
			if end_count = '1' then
				next_state <= UNBLANK ;
			end if ;
		when UNBLANK =>
			if end_count = '1' then
				next_state <= SHIFT1 ;
			end if ;
		when SHIFT1 =>
				if end_count = '1' then
					next_state <= SHIFT2 ;
				end if ;
		when SHIFT2 =>
				if end_of_col = '1' and end_count = '1' then
					next_state <= EXPOSE ;
				elsif end_count = '1' then
					next_state <= SHIFT1 ;
				end if ;
		when others =>
			next_state <= EXPOSE ;
	 end case ;
end process;				 
				 		
-- internal signals management

-- clk_count is used to generate the time interval between states
-- it is also used to generate the output clock frequency
process(gls_clk, gls_reset)
begin
    if gls_reset = '1' then
        clk_count <=  bin_code_delay;
    elsif rising_edge(gls_clk) then
		if end_count = '1' then
			clk_count <= count_load_val ;
		else
			clk_count <= clk_count - 1 ;
		end if ;
    end if;
end process;

-- helper signal to simplify equations
end_count <= '1' when clk_count = 0 else
				 '0' ;
	
-- value to in interval counter, value to load is computed for next state	
with cur_state select
	count_load_val	<= std_logic_vector(to_unsigned((clk_div*8)-1, 16) ) when EXPOSE,
							std_logic_vector(to_unsigned((clk_div*8)-1, 16) ) when BLANK,
							std_logic_vector(to_unsigned((clk_div-1), 16) )  when LATCH,
							std_logic_vector(to_unsigned((clk_div-1), 16) )  when UNBLANK,
							std_logic_vector(to_unsigned((clk_div-1), 16) ) when SHIFT1,
							next_pixel_div when SHIFT2,
							std_logic_vector(to_unsigned((clk_div-1), 16) ) when others;
							
-- handle the case when switching from SHIFT2 to SHIFT1 or SHIFT2 to EXPOSE
next_pixel_div <= bin_code_delay when end_of_col = '1' else
						std_logic_vector(to_unsigned((clk_div-1), 16) ) ;




-- column counter, is incremented on each falling edge of sclk
process(gls_clk, gls_reset)
begin
    if gls_reset = '1' then
        col_count <=  (others => '0') ;
    elsif rising_edge(gls_clk) then
		if col_count_reset = '1' then
			col_count <=  (others => '0') ;
		elsif col_count_enable = '1' then 
			col_count <= col_count + 1 ;
		end if ;
    end if;
end process;
-- helper signal to simplify equations
end_of_col <= '1' when col_count = (LINE_SIZE-1) else
					 '0' ;

-- the column count is reseted on end of blank
with cur_state select
	col_count_reset <= '0' when SHIFT1,
							 '0' when SHIFT2,
							 end_count when UNBLANK,
							 '0' when others;
-- column are counted when shifintg the pixel data
with cur_state select							 
	col_count_enable <= end_count when SHIFT2,
							  '0' when others ;


-- line counter, specify the line to read from memory
process(gls_clk, gls_reset)
begin
    if gls_reset = '1' then
        line_count <=  (others => '0') ;
    elsif rising_edge(gls_clk) then
		if line_count_enable = '1' then 
			line_count <= line_count + 1 ;
		end if ;
    end if;
end process;	

-- increment line counter after blanking
with cur_state select							 
	line_count_enable <= (end_count and rd_bit_3) when LATCH,
							  '0' when others ;	

-- rd_bit specify the bit to read from the color code 
-- exp bit specify the bit being exposed on the matrix 
process(gls_clk, gls_reset)
begin
    if gls_reset = '1' then
        rd_bit <=  (others => '0') ;
		  exp_bit <= (others => '0') ;
    elsif rising_edge(gls_clk) then
		if rd_bit_count_enable = '1' then 
			rd_bit <= rd_bit + 1 ;
			exp_bit <= rd_bit ;
		end if ;
    end if;
end process;	

with cur_state select							 
	rd_bit_count_enable <= (end_count) when LATCH,
							  '0' when others ;

-- helper signals to simplify equations
rd_bit_3 <= 	'1' when rd_bit = 3 else
					'0' ;	

-- The binary coded modulation delay is doubled for each exposed color bit
with exp_bit select
	bin_code_delay <= std_logic_vector(to_unsigned(expose_step*clk_div, 16)) when "00",
							std_logic_vector(to_unsigned(expose_step*clk_div*2, 16)) when "01",
							std_logic_vector(to_unsigned(expose_step*clk_div*4, 16)) when "10",
							std_logic_vector(to_unsigned(expose_step*clk_div*8, 16)) when others ;


-- output management

-- the output are combinatorial but latched to avoid glitches
with cur_state select
	SCLK_q <= '0' when SHIFT1,
			 '1' when SHIFT2,
			 '0' when others ;	
			 
			 
with cur_state select
	BLANK_q <= '1' when BLANK,
			 '1' when LATCH,
			 '0' when others ;	
			 
with cur_state select
	LATCH_q <= '1' when LATCH,
			 '0' when others ;	
				 

with conv_integer(rd_bit) select
	R0_q <= pixel_data_line0(8) when 0, 
			pixel_data_line0(9) when 1,
			pixel_data_line0(10) when 2,
			pixel_data_line0(11) when others;
			
with conv_integer(rd_bit) select
	G0_q <= pixel_data_line0(4) when 0, 
			pixel_data_line0(5) when 1,
			pixel_data_line0(6) when 2,
			pixel_data_line0(7) when others;
			
with conv_integer(rd_bit) select
	B0_q <= pixel_data_line0(0) when 0, 
			pixel_data_line0(1) when 1,
			pixel_data_line0(2) when 2,
			pixel_data_line0(3) when others;
			
			
with conv_integer(rd_bit) select
	R1_q <= pixel_data_line16(8) when 0, 
			pixel_data_line16(9) when 1,
			pixel_data_line16(10) when 2,
			pixel_data_line16(11) when others;
			
with conv_integer(rd_bit) select
	G1_q <= pixel_data_line16(4) when 0, 
			pixel_data_line16(5) when 1,
			pixel_data_line16(6) when 2,
			pixel_data_line16(7) when others;
			
with conv_integer(rd_bit) select
	B1_q <= pixel_data_line16(0) when 0, 
			pixel_data_line16(1) when 1,
			pixel_data_line16(2) when 2,
			pixel_data_line16(3) when others;
	
	

-- the address to be output to the matrix is a delayed version of the
-- line being read from memory. We expose one line, while we are loading the values
-- for the next
process(gls_clk, gls_reset)
begin
	 if gls_reset = '1' then
			A_OUT_Q <= (others => '0');
    elsif rising_edge(gls_clk) then
		if cur_state = BLANK and end_count = '1' then
			A_OUT_Q <= line_count ;
		end if ;
	end if;
end process;	

-- all output are latched to prevent glitches	
process(gls_clk, gls_reset)
begin
    if rising_edge(gls_clk) then
		SCLK_OUT <= SCLK_q ;
		LATCH_OUT <= LATCH_q ;
		BLANK_OUT <= BLANK_q ;
		R_OUT(0) <= R0_q ;
		R_OUT(1) <= R1_q ;
		G_OUT(0) <= G0_q ;
		G_OUT(1) <= G1_q ;
		B_OUT(0) <= B0_q ;
		B_OUT(1) <= B1_q ;
		A_OUT <= A_OUT_Q ;
	end if;
end process;	
	
	

end Behavioral;


