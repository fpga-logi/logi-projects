----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:08:26 08/30/2013 
-- Design Name: 
-- Module Name:    samples2fifo - Behavioral 
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity samples2fifo is
port(
		clk, rst : in std_logic ;
		
		frame_info : in std_logic_vector(15 downto 0);
		timestamp : in std_logic_vector(31 downto 0);
		frame0 : in std_logic ;
		data : in std_logic_vector(23 downto 0);
		data_valid : in std_logic ;
		
		
		fifo_write : out std_logic ;
		fifo_data : out std_logic_vector(15 downto 0);
		fifo_full : in std_logic 
);
end samples2fifo;

architecture Behavioral of samples2fifo is


signal sync_reset, sync_reset_d : std_logic;
signal buffer48 : std_logic_vector(47 downto 0);
signal transmit_buffer : std_logic_vector(47 downto 0);
signal sample_count : std_logic_vector(1 downto 0) ;
signal sent_counter, ts_send_counter : std_logic_vector(1 downto 0) ;
signal frame0_old, frame0_re : std_logic ;
begin



process(clk, rst)
begin
	if rst = '1' then
		sync_reset_d <= '1' ;
	elsif clk'event and clk = '1' then
		if frame0_re = '1' and data_valid = '1' then
			sync_reset_d <= '0' ;
		end if ; 
	end if ;
end process ;
sync_reset <= sync_reset_d and not(frame0_re and data_valid);

process(clk, rst)
begin
	if rst = '1' then
		buffer48 <= (others => '0');
	elsif clk'event and clk = '1' then
		if sync_reset = '1' then
			buffer48 <= (others => '0');
		elsif data_valid = '1' then
			buffer48(47 downto 24) <= buffer48(23 downto 0) ;
			buffer48(23 downto 0) <= data ;
		end if ;
		
	end if ;
end process ;

process(clk, rst)
begin
	if rst = '1' then
		sample_count <= (others => '0');
	elsif clk'event and clk = '1' then
		if sync_reset = '1' then
			sample_count <= (others => '0');
		elsif sample_count=2 then
			sample_count <= (others => '0');
		elsif data_valid = '1' then
			sample_count <= sample_count + 1 ;
		end if ;
	end if ;
end process ;

process(clk, rst)
begin
	if rst = '1' then
		transmit_buffer <= (others => '0');
	elsif clk'event and clk = '1' then
		if sync_reset = '1' then
			transmit_buffer <= (others => '0');
		elsif sample_count = 2 then
			transmit_buffer <= buffer48 ;
		end if ;
	end if ;
end process ;

process(clk, rst)
begin
	if rst = '1' then
		sent_counter <= (others => '0');
	elsif clk'event and clk = '1' then
		if sync_reset = '1' then
			sent_counter <= (others => '0');
		elsif sent_counter = 2 then
			sent_counter <= (others => '0');
		elsif sent_counter > 0 or  sample_count = 2 then
			sent_counter  <= sent_counter  + 1 ;
		end if ;
	end if ;
end process ;

process(clk, rst)
begin
	if rst = '1' then
		ts_send_counter <= (others => '0');
	elsif clk'event and clk = '1' then
		if frame0_re = '1' and data_valid = '1' then
			ts_send_counter <= "10"; -- load with value
		elsif ts_send_counter > 0 then
			ts_send_counter  <= ts_send_counter  - 1 ; --decrement until zero
		end if ;
	end if ;
end process ;

process(clk, rst)
begin
	if rst = '1' then
		frame0_old <= '0' ;
	elsif clk'event and clk = '1' then
		frame0_old <= frame0 ;
	end if ;
end process ;

frame0_re <= frame0 and (not frame0_old) ;


fifo_data <= frame_info when frame0_re =  '1' else
				 timestamp(15 downto 0) when ts_send_counter = 2 else 
				 timestamp(31 downto 16) when ts_send_counter = 1 else
				 buffer48(15 downto 0) when sent_counter = "00" else -- written when buffer not yet loaded
				 transmit_buffer(31 downto 16) when sent_counter = "01" else
				 transmit_buffer(47 downto 32) when sent_counter = "10" else
				 X"0000";
					 
fifo_write <= 	'1' when sent_counter > 0 else
					'1' when sample_count = 2 else
					'1' when ts_send_counter > 0 else
					(frame0_re and data_valid) ;--frame0_re  ; -- writing the last frame infos

end Behavioral;

