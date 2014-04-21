----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:15:55 04/02/2014 
-- Design Name: 
-- Module Name:    spdif_48k_ds - Behavioral 
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

entity spdif_48k_ds is
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
end spdif_48k_ds;

architecture Behavioral of spdif_48k_ds is

constant ds96_modulo : positive := 2 ;
constant ds192_modulo : positive := 4 ;

type slv24_array is array (natural range <>) of std_logic_vector(23 downto 0);
signal sample_r_buffer, sample_l_buffer : slv24_array(0 to 1) ; -- dowsampling buffers
signal l_sample_count, r_sample_count : std_logic_vector(1 downto 0) ;
signal data_l_out, data_r_out : std_logic_vector(23 downto 0);
signal data_valid_ds, frame0_ds, frame0_out_temp : std_logic ;
signal data_ds, data_out_temp : std_logic_vector(23 downto 0);
signal synced, synced_latched : std_logic ;
signal frame0_old, frame0_re, frame0_fe : std_logic ;
signal frame0_counter : std_logic_vector(1 downto 0);
signal chan1_en_ds, chan2_en_ds, chan1_en_out_temp, chan2_en_out_temp : std_logic ;
signal sample_count_modulo : std_logic_vector(1 downto 0) ;
signal rate_out_temp : std_logic_vector(3 downto 0);
signal rate_in_latched : std_logic_vector(3 downto 0); 
begin

process(clk, reset)
begin
	if reset = '1' then
		synced_latched <= '0' ;
		rate_in_latched <= (others => '0') ;
	elsif clk'event and clk = '1' then
		if frame0_in = '1' then
			synced_latched <= '1' ;
		end if ;
		rate_in_latched <= rate_in ;
	end if ;
end process ;
synced <= frame0_in when synced_latched='0' else
			 synced_latched ;


--TODO: synchronize on frame0 to start accumulating data in the L/R buffers
--TODO: based on the frame_info decide if downsampling is required
--TODO: sub-sample the frame0 signal to output it only once over two
with rate_in(3 downto 0) select
	data_out_temp <= data_in when "1010", -- 44khz, no downsampling
					data_in when "0010", -- 48khz, no downsampling
					data_ds when "0011", -- 96khz, downsampling
					data_ds when "0100", -- 192khz, downsampling
					data_in when others ;
					
with rate_in(3 downto 0) select
	frame0_out_temp <= frame0_in when "1010", -- 44khz, no downsampling
					frame0_in when "0010", -- 48khz, no downsampling
					frame0_ds when "0011", -- 96khz, downsampling
					frame0_ds when "0100", -- 192khz, downsampling
					frame0_in when others ;
					
with rate_in(3 downto 0) select
	rate_out_temp(3 downto 0) <= rate_in(3 downto 0) when "1010", -- 44khz, no downsampling
					rate_in(3 downto 0) when "0010", -- 48khz, no downsampling
					"0010" when "0011", -- 96khz, downsampling
					"0011" when "0100", -- 192khz, downsampling
					rate_in(3 downto 0) when others ;
					

with rate_in(3 downto 0) select
	chan1_en_out_temp <= chan1_en_in when "1010", -- 44khz, no downsampling
					chan1_en_in when "0010", -- 48khz, no downsampling
					chan1_en_ds when "0011", -- 96khz, downsampling
					chan1_en_ds when "0100", -- 192khz, downsampling
					chan1_en_in when others ;


with rate_in(3 downto 0) select
	chan2_en_out_temp <= chan2_en_in when "1010", -- 44khz, no downsampling
					chan2_en_in when "0010", -- 48khz, no downsampling
					chan2_en_ds when "0011", -- 96khz, downsampling
					chan2_en_ds when "0100", -- 192khz, downsampling
					chan2_en_in when others ;	


with rate_in(3 downto 0) select
	sample_count_modulo <= (others => '0') when "1010", -- 44khz, no downsampling
					(others => '0') when "0010", -- 48khz, no downsampling
					std_logic_vector(to_unsigned(ds96_modulo-1,2)) when "0011", -- 96khz, downsampling
					std_logic_vector(to_unsigned(ds192_modulo-1,2)) when "0100", -- 192khz, downsampling
					(others => '0') when others ;						
					

process(clk, reset)
begin
	if reset = '1' then
		frame0_old <= '0' ;
	elsif clk'event and clk = '1' then
		frame0_old <= frame0_in ;
	end if ;
end process ;
frame0_re <= frame0_in and (not frame0_old);
frame0_fe <= (not frame0_in) and  frame0_old;

process(clk, reset)
begin
	if reset = '1' then
		sample_r_buffer <= (others => (others => '0'));
		sample_l_buffer <= (others => (others => '0'));
		l_sample_count <= (others => '0');
		r_sample_count <= (others => '0');
	elsif clk'event and clk = '1' then
		if chan1_en_in = '1' then
			sample_r_buffer(0) <= data_in ;
			sample_r_buffer(1) <= sample_r_buffer(0) ;
			if r_sample_count = sample_count_modulo then
				r_sample_count <= (others => '0');
			else
				r_sample_count <= r_sample_count + 1 ;
			end if ;
		elsif chan2_en_in = '1' then
			sample_l_buffer(0) <= data_in ;
			sample_l_buffer(1) <= sample_l_buffer(0) ;
			if l_sample_count = sample_count_modulo then
				l_sample_count <= (others => '0');
			else
				l_sample_count <= l_sample_count + 1 ;
			end if ;
		end if ;
	end if ;
end process ;


process(clk, reset)
begin
	if reset = '1' then
		frame0_counter <= (others => '0');
	elsif clk'event and clk = '1' then
		if frame0_fe = '1' then
			if frame0_counter = sample_count_modulo then
				frame0_counter <= (others => '0') ;
			else
				frame0_counter <= frame0_counter + 1 ;
			end if;
		end if ;
	end if ;
end process ;

data_l_out <= sample_l_buffer(1) ;
data_r_out <= sample_r_buffer(1) ;

chan1_en_ds <= chan1_en_in when r_sample_count = sample_count_modulo else
					 '0' ;
					 
chan2_en_ds <= chan2_en_in when l_sample_count = sample_count_modulo else
					 '0' ;
					 
data_ds <= data_l_out when chan1_en_in = '1' else
			  data_r_out ;
					  
frame0_ds <= frame0_in when frame0_counter = 0 else '0' ;

process(clk, reset)
begin
	if reset = '1' then
		frame0_out <= '0' ;
		data_out <= (others => '0');
		chan1_en_out <= '0' ;
		chan2_en_out <= '0' ;
		rate_out <= (others => '0');
	elsif clk'event and clk = '1' then
		frame0_out <= frame0_out_temp ;
		data_out <= data_out_temp;
		chan1_en_out <= chan1_en_out_temp ;
		chan2_en_out <= chan2_en_out_temp ;
		rate_out <= rate_out_temp;
	end if ;
end process ;


end Behavioral;

