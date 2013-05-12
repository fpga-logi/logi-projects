----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    02:50:10 04/24/2013 
-- Design Name: 
-- Module Name:    servo_controller - Behavioral 
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
use ieee.std_logic_unsigned.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity servo_controller is
  generic(
    clock_period             : integer := 128;
    minimum_high_pulse_width : integer := 1000000;
    maximum_high_pulse_width : integer := 2000000
    );
  port (clk            : in  std_logic;
        rst            : in  std_logic;
        servo_position : in  std_logic_vector (0 to 7);
        servo_out       : out std_logic);
end servo_controller;

architecture Behavioral of servo_controller is
  constant servo_PWM_period                      : integer := 20000000;
  constant servo_PWM_clock_periods               : integer := servo_PWM_period/clock_period;
  constant PWM_resolution_per_step               : integer := ((maximum_high_pulse_width - minimum_high_pulse_width)/  2**(servo_position'length));
  constant PWM_resolution_per_step_clock_periods : integer := PWM_resolution_per_step / clock_period;
  constant minimum_low_pulse_width               : integer := servo_pwm_period - maximum_high_pulse_width;
  constant minimum_high_pulse_width_clock_period : integer := minimum_high_pulse_width / clock_period;
  constant maximum_high_pulse_width_clock_period : integer := maximum_high_pulse_width / clock_period;

  signal variable_high_pulse_width     : integer;
  signal variable_low_pulse_width      : integer;
  signal high_pulse_width              : integer;
  signal low_pulse_width               : integer;
  signal high_pulse_width_clock_period : integer;
  signal low_pulse_width_clock_period  : integer;
  type   main_fsm_type is (reset, low_period, high_period);

  signal control_counter           : integer range 0 to servo_pwm_clock_periods;
  signal reset_control_counter     : std_logic := '0';
  signal current_state, next_state : main_fsm_type;
  
begin
  
  variable_high_pulse_width <= (to_integer(unsigned(servo_position))) * pwm_resolution_per_step;
  variable_low_pulse_width  <= maximum_high_pulse_width - (minimum_high_pulse_width + variable_high_pulse_width);
  high_pulse_width          <= minimum_high_pulse_width + variable_high_pulse_width;
  low_pulse_width           <= minimum_low_pulse_width + variable_low_pulse_width;

  high_pulse_width_clock_period <= high_pulse_width /clock_period;
  low_pulse_width_clock_period  <= low_pulse_width / clock_period;

  state_machine_update : process(clk, rst)
  begin
    if (rst = '1') then
      current_state <= reset;
    else
      current_state <= next_state;
    end if;
  end process;
  st_mach_dec : process(current_state, control_counter, high_pulse_width_clock_period, low_pulse_width_clock_period)
  begin
    servo_out             <= '0';
    reset_control_counter <= '0';
    case current_state is
      when reset =>
        reset_control_counter <= '1';
        next_state            <= low_period;
        
      when low_period =>
        if (control_counter >= low_pulse_width_clock_period) then
          reset_control_counter <= '1';
          next_state            <= high_period;
        else
          next_state <= low_period;
        end if;
        
      when high_period =>
        servo_out <= '1';
        if (control_counter >= high_pulse_width_clock_period) then
          reset_control_counter <= '1';
          next_state            <= low_period;
        else
          next_state <= high_period;
        end if;
        
      when others =>
        next_state <= reset;
    end case;
  end process;

  inst_control_counter : process(clk, rst)
  begin
    if (clk'event and clk = '1') then
      if (reset_control_counter = '1') then
        control_counter <= 0;
      elsif(control_counter = servo_pwm_clock_periods) then
        control_counter <= 0;
      else
        control_counter <= control_counter + 1;
      end if;
    end if;
  end process;
  
  
end Behavioral;

