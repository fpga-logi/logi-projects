----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:57:37 05/11/2013 
-- Design Name: 
-- Module Name:    PID_Controller - Behavioral 
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
library ieee_proposed;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee_proposed.fixed_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PID_Controller is
  generic(DataWidthIn  : integer range 8 to 32 := 16;
          DataWidth    : integer range 8 to 32 := 16;
          PidDataWidth : integer range 8 to 32 := 16;
          DataWidthOut : integer range 8 to 32 := 8);
  port (clk : in std_logic;
        rst : in std_logic;

        pid_ref : in  std_logic_vector(PidDataWidth-1 downto 0);  -- PID reference value sent from RPI
        pid_fdb : in  std_logic_vector(PidDataWidth-1 downto 0);  -- PID feedback signal from encoder
        pid_en  : in  std_logic;
        pid_cmp : out std_logic;
        pid_out : out std_logic_vector(PidDataWidth-1 downto 0)
        );
end PID_Controller;

architecture Behavioral of PID_Controller is
  
  shared variable Kprop  : signed(15 downto 0)   := to_signed(35, 16);
  shared variable Kpropf : sfixed(15 downto -16) := to_sfixed(35.676, 15, -16);
  shared variable Kint   : sfixed(15 downto -16) := to_sfixed(102, 15, -16);
  shared variable Kder   : signed(15 downto 0)   := to_signed(0, 16);
  shared variable Kderf  : sfixed(15 downto -16) := to_sfixed(90, 15, -16);

  signal error : signed(PidDataWidth-1 downto 0)   := to_signed(0, 16);  -- Error based on Reference signal and Encoder Feedback Value
  signal Upf   : sfixed(PidDataWidth-1 downto -16) := to_sfixed(0, 15, -16);  -- Error based on Reference signal and Encoder Feedback Value

  signal Up      : signed(15 downto 0) := to_signed(0, 16);
  signal Up_prev : signed(15 downto 0) := to_signed(0, 16);
  signal Ui      : signed(15 downto 0) := to_signed(0, 16);
  signal Uif     : signed(15 downto 0) := to_signed(0, 16);
  signal Ud      : signed(15 downto 0) := to_signed(0, 16);



  signal pid_en_s1 : std_logic;
  signal pid_en_s2 : std_logic;
  signal pid_en_s3 : std_logic;
  signal pid_en_s4 : std_logic;
  signal pid_en_s5 : std_logic;

  signal pid_cmp_i   : std_logic;
  signal pid_compute : signed(15 downto 0) := to_signed(0, 16);
begin
  
  process(clk)
  begin
    if (rst = '0') then
      pid_en_s1 <= '0';
    elsif(clk'event and clk = '1') then
      pid_en_s1 <= pid_en;
      pid_en_s2 <= pid_en_s1;
      pid_en_s3 <= pid_en_s2;
      pid_en_s4 <= pid_en_s3;
      pid_en_s5 <= pid_en_s4;
    end if;
  end process;

--**********************************************************************
-- Compute Error
--**********************************************************************
  Error_Calc : process(clk, rst)
  begin
    if (clk'event and clk = '1') then
      if(rst = '0') then
        error <= (others => '0');
      elsif(Pid_ref > Pid_fdb) then
        error <= resize(signed(unsigned(pid_ref))-signed(unsigned(pid_fdb)), 16);
      elsif(Pid_fdb >= Pid_ref) then
        error <= resize(signed(unsigned(pid_fdb))-signed(unsigned(pid_ref)), 16);
      end if;
    end if;
  end process;
--**********************************************************************
-- Compute Proportional
--**********************************************************************
  Proportional_Control : process(clk)
  begin
    if(clk'event and clk = '1')then
      if(rst = '0') then
        Up <= (others => '0');
      elsif(pid_en_s2 = '1') then
        Up <= to_signed(resize(Kpropf * to_sfixed(error, 15, -16), 15, -16), 16);
      end if;
    end if;
  end process;
--**********************************************************************
-- Compute Integration
--**********************************************************************
  Integrative_Control : process(clk)
  begin
    if(clk'event and clk = '1') then
      if (rst = '0') then
        Ui <= (others => '0');
      elsif(Pid_Ref > Pid_fdb) then
        Ui <= Ui + to_signed(resize(Kint * to_sfixed(Up, 15, -16), 15, -16), 16);
      elsif(Pid_Fdb >= Pid_Ref) and (Ui >= to_signed((Kint* to_sfixed(Up, 15, -16)), 16)) then
        Ui <= Ui - to_signed(resize(Kint * to_sfixed(Up, 15, -16), 15, -16), 16);
      end if;
    end if;
  end process;
--**********************************************************************
-- Compute Derivation
--**********************************************************************
  Derivative_Control : process(clk)
  begin
    if (clk'event and clk = '1') then
      if (rst = '0') then
        Ud <= (others => '0');
      elsif(pid_en_s4 = '1') then
        Ud      <= to_signed(Kderf* resize(to_sfixed(Up - Up_Prev), 15, -16), 16);
        Up_Prev <= Up;
      end if;
    end if;
  end process;
--**********************************************************************
-- Compute Output
--**********************************************************************
  Final_Output : process(clk)
  begin
    if (clk 'event and clk = '1') then
      pid_compute <= abs(pid_compute);
      pid_out     <= std_logic_vector(pid_compute);
      if(rst = '0') then
        pid_out <= (others => '0');
      end if;
    else
      pid_compute <= (Up + Ui + Ud);
    end if;

  end process;

  
end Behavioral;

