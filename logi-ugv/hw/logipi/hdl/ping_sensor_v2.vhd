------------------------------------------------------------------------------------
--state machine:
--1) idle: wait for the period to start the ping sensing
--2) trigger: send the 10us trigger pulse 
--3) wait echo: wait for the echo high edge, if timeout_cnt reaches 50ms, restart
--4) echo count: echo rising edge received begin count, end count when echo falling edge, if timeout_cnt reaches 50ms, restart
--5) wait next: wait for timeout to reach 50ms.
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all;

entity ping_sensor_v2 is
generic (CLK_FREQ_NS : positive := 20);
port( clk : in std_logic;
		reset: in std_logic;
		ping_io: inout std_logic;
		ping_enable: in std_logic;
		echo_length : out std_logic_vector(15 downto 0);
		echo_done_out: out std_logic;
		state_debug: out std_logic_vector(1 downto 0);
		timeout: out std_logic;
		busy : out std_logic 
);
end ping_sensor_v2;

architecture Behavioral of ping_sensor_v2 is
	type state_type is (idle, trigger, echo_wait, echo_cnt,wait_next); --,wait_sample_period);
	signal state_reg, state_next: state_type;
	
	--@50Mhz
	constant VAL_1us :integer:= 1_000/CLK_FREQ_NS;
	
	--constant VAL_WAIT_NEXT_PING := 100;  --200us -- found that at least 170 us need on the parallax sensor.
	constant VAL_10us :integer:= 10 ; 	--10us 
	constant TIMEOUT_VAL: integer := 50_000; --100ms
	
	signal ping_cnt_r: unsigned(31 downto 0);  --general purpose counter used in state mahine
	signal ping_cnt_rst: std_logic;
	signal echo_done: std_logic;
	signal echo_clk_val_n, echo_clk_val_r : unsigned(31 downto 0);

	signal cnt_timeout_r: unsigned(31 downto 0);	--timeout signals
	
	signal timeout_cnt_r: unsigned(31 downto 0);
	signal timeout_cnt_rst: std_logic;

	signal trigger_out_temp : std_logic ;
	signal trigger_out, echo_in: std_logic;

	
	signal end_usec, load_usec_counter : std_logic ;
	signal usec_counter : std_logic_vector(31 downto 0);
begin	

ping_io <= trigger_out when state_reg = trigger else 'Z';
echo_in <= ping_io;

--register
process(clk, reset)
begin
	if reset = '1' then
		state_reg <= idle;
	elsif clk'event and clk = '1' then
		state_reg <= state_next;
	end if;
end process ;

--need to pull out the counters!
process(state_reg, ping_enable, echo_in, ping_cnt_r, timeout_cnt_r)
begin
	state_next <= state_reg;

	case state_reg is 
		
		when idle => 
			if (ping_enable = '1') then	--start trigger sequence
				state_next <= trigger;				
			end if;
					
		when trigger =>
			if (ping_cnt_r >= VAL_10US) then
				state_next <= echo_wait;
			end if;	
					
		when echo_wait =>	--wait for echo to go high
			if (echo_in = '1') then		--echo went high
				state_next <= echo_cnt;	
			elsif (timeout_cnt_r >= TIMEOUT_VAL) then
				state_next <= idle;
			end if;	
			
		when echo_cnt =>					--cnt length of echo pulse
			if (echo_in = '0') then		--ECHO received - DONE!
				--state_next <= wait_sample_period;
				state_next <= wait_next;
			elsif (timeout_cnt_r >= TIMEOUT_VAL) then	--check to see if the timeout
				state_next <= idle;
			end if;	

		when	wait_next	=>	-- wait end of timeout to start next measurement
			if (timeout_cnt_r >= TIMEOUT_VAL) then
			--if (timeout_cnt_r >= VAL_WAIT_NEXT_PING) then
					
				state_next  <= idle;
			end if;	
	end case;
end process;

with state_reg select
	state_debug <= "00" when idle,
						"01" when trigger,
						"10" when echo_wait,
						"11" when echo_cnt,
						"00" when others ;

ping_cnt_rst <= '1' when state_reg = idle else
					 '1' when state_reg = echo_wait and echo_in = '1' else
					 '1' when state_reg = echo_cnt and echo_in = '0' else
					 '0' ;

timeout_cnt_rst <= '1' when state_reg = idle else
					'1' when state_reg = trigger and ping_cnt_r >= VAL_10US else
					'0' ;
						 						 
trigger_out_temp <= '1' when state_reg = trigger else
					'0' ;

					 
echo_done <= '1' when state_reg = echo_cnt and echo_in = '0' else	
				 '0' ;
				 
timeout <= '1' when state_reg = echo_wait and timeout_cnt_r >= TIMEOUT_VAL else	
			  '1' when state_reg = echo_cnt and timeout_cnt_r >= TIMEOUT_VAL else
			  '0' ;

busy <= '0' when state_reg = idle and ping_enable = '0' else
			'1' ;

-- timeout counter 
process(clk, reset)
begin
	if reset = '1' then
		timeout_cnt_r <= (others => '0');
	elsif clk'event and clk = '1' then
		if timeout_cnt_rst = '1' then
			timeout_cnt_r <= (others => '0');
		elsif end_usec = '1' then
			timeout_cnt_r <= timeout_cnt_r + 1 ;
		end if ;
	end if ;
end process ;

-- ping counter 
process(clk, reset)
begin
	if reset = '1' then
		ping_cnt_r <= (others => '0');
	elsif clk'event and clk = '1' then
		if ping_cnt_rst = '1' then
			ping_cnt_r <= (others => '0');
		elsif end_usec = '1' then
			ping_cnt_r <= ping_cnt_r + 1 ;
		end if ;
	end if ;
end process ;

-- usec counter
process(clk, reset)
begin
	if reset = '1' then
		usec_counter <= std_logic_vector(to_unsigned(VAL_1us-1, 32));
	elsif clk'event and clk = '1' then
		if load_usec_counter = '1' then
			usec_counter <= std_logic_vector(to_unsigned(VAL_1us-1, 32));
		else
			usec_counter <= usec_counter - 1 ;
		end if ;
	end if ;
end process ;
end_usec <= 			'1' when usec_counter = 0 else
						'0' ;
load_usec_counter <= '1' when state_reg = idle else
							end_usec;

--result latch
process(clk, reset)
begin
	if reset = '1' then
		echo_clk_val_r <= (others => '0');
	elsif clk'event and clk = '1' then
		if echo_done = '1' then
			echo_clk_val_r <= ping_cnt_r ;
		end if ;
	end if ;
end process ;

process(clk, reset)
begin
	if reset = '1' then
		trigger_out <= '0';
	elsif clk'event and clk = '1' then
		trigger_out <= trigger_out_temp ;
	end if ;
end process ;


						
echo_length <= std_logic_vector(echo_clk_val_r(15 downto 0)) ;						
echo_done_out <= echo_done;

end Behavioral;


