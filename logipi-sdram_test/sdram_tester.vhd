----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:45:45 05/08/2013 
-- Design Name: 
-- Module Name:    sdram_tester - Behavioral 
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

entity sdram_tester is
generic(ADDR_WIDTH : positive := 24;
		DATA_WIDTH : positive := 32);
port(
	clk, resetn : in std_logic ;
	address : out std_logic_vector(ADDR_WIDTH-1 downto 0);
	data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
	data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
	rd : out std_logic ;
	wr : out std_logic ;
	pending : in std_logic ;
	data_valid : in std_logic;
	
	test_done :out std_logic ;
	test_failed : out std_logic 
	);
end sdram_tester;

architecture Behavioral of sdram_tester is
type tester_state is (INIT, WRITE_SDRAM, READ_SDRAM, WAIT_VALID, DONE);

constant addr_count_max : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '1');
constant cycle_count_max : std_logic_vector(1 downto 0) := (others => '1');


signal state, next_state : tester_state ;
signal addr_count : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
signal reset_addr_count, en_addr_count : std_logic ;
signal cycle_count : std_logic_vector(1 downto 0);
signal reset_cycle_count, en_cycle_count : std_logic ;
signal current_data : std_logic_vector(DATA_WIDTH-1 downto 0);
signal addr_data : std_logic_vector(DATA_WIDTH-1 downto 0);
signal failed_d, failed_en : std_logic ;
begin

addr_data(ADDR_WIDTH-1 downto 0) <= addr_count ;
addr_data(DATA_WIDTH-1 downto ADDR_WIDTH) <= (others => '0');

current_data <= (others => '0') when cycle_count = 0 else
						(others => '1') when cycle_count = 1 else
						X"AA55AA55" when cycle_count = 2 else
						addr_data when cycle_count = 3 ;
data_out <= current_data ;

process(clk, resetn)
begin
	if resetn = '0' then	
		state <= INIT ;
	elsif clk'event and clk = '1' then
		state <= next_state ;
	end if ;
end process ;

with state select
	en_addr_count <= (not pending) when WRITE_SDRAM,
						  (data_valid) when WAIT_VALID,
						  '1' when INIT,
						   '0' when others ;
							
with state select
	reset_addr_count <=  '1' when DONE,
								--'1' when INIT, --only for sim
								'0' when others ;
process(clk, resetn)
begin
	if resetn = '0' then	
		addr_count <= (others => '0');
	elsif clk'event and clk = '1' then
		if reset_addr_count = '1' then
			addr_count <= (others => '0');
		elsif en_addr_count = '1' then
			addr_count <= addr_count + 1 ;
		end if ;
	end if ;
end process ;
address <= addr_count ;

en_cycle_count <= '1' when state = WAIT_VALID and data_valid = '1' and addr_count = addr_count_max else
						'0';
							
with state select
	reset_cycle_count <=  '1' when INIT,
								 '0' when others ;
process(clk, resetn)
begin
	if resetn = '0' then	
		cycle_count <= (others => '0');
	elsif clk'event and clk = '1' then
		if reset_cycle_count = '1' then
			cycle_count <= (others => '0');
		elsif en_cycle_count = '1' then
			cycle_count <= cycle_count + 1 ;
		end if ;
	end if ;
end process ;


process(state, addr_count, cycle_count, data_in, pending, data_valid)
begin
	next_state <= state ;
	case state is
		when INIT =>
			if addr_count = addr_count_max then
				next_state <= WRITE_SDRAM ;
			end if ;
		when WRITE_SDRAM =>
			if addr_count = addr_count_max and pending = '0' then
				next_state <= READ_SDRAM ;
			end if ;
		when READ_SDRAM =>
			if pending = '0' then
				next_state <= WAIT_VALID ;
			end if ;
		when WAIT_VALID =>
			if data_valid = '1' and data_in /= current_data then
				next_state <= DONE ;
			elsif data_valid = '1' and addr_count = addr_count_max and cycle_count = cycle_count_max then
				next_state <= DONE ;
			elsif data_valid = '1' and addr_count = addr_count_max then
				next_state <= WRITE_SDRAM ;
			elsif data_valid = '1' then
				next_state <= READ_SDRAM ;
			end if ;
		when DONE =>
		when others =>
			next_state <= INIT;
	end case ;
end process ;

failed_d <= '1' when state = WAIT_VALID and data_valid = '1' and data_in /= current_data else
				'0' ;
failed_en <= failed_d ;

process(clk, resetn)
begin
	if resetn = '0' then	
		test_failed <= '0';
	elsif clk'event and clk = '1' then
		if failed_en = '1' then
			test_failed <= failed_d;
		end if ;
	end if ;
end process ;

test_done <= '1' when state = DONE else
				 '0' ;

with state select
	wr <= (not pending) when WRITE_SDRAM,
			'0' when others ;
			
with state select
	rd <= '1' when READ_SDRAM,
			'0' when others ;


end Behavioral;

