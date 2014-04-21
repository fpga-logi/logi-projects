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

entity samples162fifo is
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
end samples162fifo;

architecture Behavioral of samples162fifo is
constant SAMPLE_INDEX : integer := 2 ;
type slv16_array is array(0 to 3) of std_logic_vector(15 downto 0);

signal sync_reset, sync_reset_d : std_logic;
signal sample_delay : slv16_array;
signal sample_valid_delay : std_logic_vector(0 to 3);
signal ts_send_counter : std_logic_vector(1 downto 0) ;
signal frame0_old, frame0_re : std_logic ;
signal data_valid_old, data_valid_re : std_logic ;
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
		sample_delay <= (others =>(others => '0'));
		sample_valid_delay <= (others => '0');
		data_valid_old <= '0' ;
	elsif clk'event and clk = '1' then
		if sync_reset = '1' then
			sample_delay <= (others =>(others => '0'));
			sample_valid_delay <= (others => '0');
		else 
			sample_delay(0) <= data(23 downto 8);
			sample_delay(1 to 3) <= sample_delay(0 to 2);
			sample_valid_delay(0) <= (data_valid xor data_valid_old) and data_valid;
			sample_valid_delay(1 to 3) <= sample_valid_delay(0 to 2);
			data_valid_old <= data_valid ;
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
				 sample_delay(SAMPLE_INDEX) ; -- sample delayed 
					 
fifo_write <= 	data_valid when frame0_re = '1' else
					'1' when ts_send_counter > 0 else -- writing timestamp info
					sample_valid_delay(SAMPLE_INDEX) ;-- writing delayed sample

end Behavioral;

