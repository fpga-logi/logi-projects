----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:56:26 05/26/2014 
-- Design Name: 
-- Module Name:    wishbone_ping - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wishbone_ping is
generic(	nb_ping : positive := 2;
			clock_period_ns           : integer := 10
		  );
port(
		  -- Syscon signals
		  gls_reset    : in std_logic ;
		  gls_clk      : in std_logic ;
		  -- Wishbone signals
		  wbs_address       : in std_logic_vector(15 downto 0) ;
		  wbs_writedata : in std_logic_vector( 15 downto 0);
		  wbs_readdata  : out std_logic_vector( 15 downto 0);
		  wbs_strobe    : in std_logic ;
		  wbs_cycle      : in std_logic ;
		  wbs_write     : in std_logic ;
		  wbs_ack       : out std_logic;
			
	     trigger : out std_logic_vector(nb_ping-1 downto 0 );
		  echo : in std_logic_vector(nb_ping-1 downto 0)

);
end wishbone_ping;

architecture Behavioral of wishbone_ping is

component ping_sensor_v2 is
generic (CLK_FREQ_NS : positive := 20);
port( clk : in std_logic;
		reset: in std_logic;
		trigger_out: out std_logic;
		echo_in: in std_logic;
		ping_enable: in std_logic;
		state_debug: out std_logic_vector(1 downto 0);
		echo_length : out std_logic_vector(15 downto 0);
		echo_done_out: out std_logic;
		timeout: out std_logic;
		busy : out std_logic 
);
end component;

type reg16_array is array (0 to (nb_ping-1)) of std_logic_vector(15 downto 0) ;

signal ping_regs : reg16_array ;


signal read_ack : std_logic ;
signal write_ack : std_logic ;

signal sensor_counter : std_logic_vector(3 downto 0); -- should depend on the number of sensor
signal active_trigger, active_echo, ping_enable, echo_done, busy : std_logic ;
signal echo_length : std_logic_vector(15 downto 0);
signal enable_reg : std_logic_vector(15 downto 0);

begin


wbs_ack <= read_ack or write_ack;

write_bloc : process(gls_clk,gls_reset)
begin
    if gls_reset = '1' then 
        write_ack <= '0';
    elsif rising_edge(gls_clk) then
        if ((wbs_strobe and wbs_write and wbs_cycle) = '1' ) then
				enable_reg <= wbs_writedata ;
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


wbs_readdata <= ping_regs(conv_integer(wbs_address)) ;


pinger :  ping_sensor_v2
generic map(CLK_FREQ_NS => clock_period_ns) 
port map( 
			clk => gls_clk,
			reset => gls_reset,
			trigger_out => active_trigger,
			echo_in =>  active_echo,
			ping_enable => ping_enable,
			state_debug => open,
			echo_length => echo_length,
			echo_done_out => echo_done,
			timeout => open,
			busy => busy
);


gen_trigs_echo : for i in 0 to nb_ping-1 generate
	trigger(i) <=  active_trigger when sensor_counter = i else
					'0' ;
end generate ;		

ping_enable <= '1' when enable_reg(conv_integer(sensor_counter)) = '1' else
						'0' ;

active_echo <= echo(conv_integer(sensor_counter)) ;

process(gls_clk, gls_reset)
begin
	if gls_reset = '1' then
			sensor_counter <= std_logic_vector(to_unsigned(nb_ping-1, 4)) ;
	elsif gls_clk'event and gls_clk = '1' then
		if sensor_counter = 0 then
			sensor_counter <= std_logic_vector(to_unsigned(nb_ping-1, 4));
		elsif busy = '0' then
			sensor_counter <= sensor_counter - 1 ;
		end if ;
	end if ;
end process ;

process(gls_clk, gls_reset)
begin
	if gls_reset = '1' then
			ping_regs <= (others => (others => '0'));
	elsif gls_clk'event and gls_clk = '1' then
		if echo_done = '1' then
			ping_regs(conv_integer(sensor_counter)) <= echo_length;
		end if ;
	end if ;
end process ;


end Behavioral;

