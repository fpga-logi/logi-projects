----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:06:40 10/08/2013 
-- Design Name: 
-- Module Name:    hear_aes_receiver - Behavioral 
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
library work ;
use work.logi_wishbone_peripherals_pack.all ;


entity hear_aes_receiver is
generic(nb_aes_channel : positive := 3; 
			wb_data_width : positive := 16;
			wb_add_width : positive := 16 ;
			CLOCK_FREQUENCY   : positive := 120000000;
			CMP_VAL_LSB       : positive := 4;
			JITTER_ALLOWANCE  : positive := 2
			);
port(
		-- Syscon signals
	gls_reset    : in std_logic ;
	gls_clk      : in std_logic ;
	
	
	audio_reset : in std_logic ;
	audio_clk : in std_logic ;
	aes_rx_input : in std_logic_vector(nb_aes_channel-1 downto 0) ;
	
	fifo_wr : out std_logic_vector(nb_aes_channel-1 downto 0) ;
	fifo_full : in std_logic_vector(nb_aes_channel-1 downto 0) ;
	fifo_data : out slv16_array(nb_aes_channel-1 downto 0);
	
	flag_register : out slv16_array(nb_aes_channel-1 downto 0);
	control_register : in slv16_array(nb_aes_channel-1 downto 0)
	
);
end hear_aes_receiver;

architecture Behavioral of hear_aes_receiver is


component aes_rx
	port (
	  clk:                    in  std_logic;     
	  rst:                    in  std_logic;     
	  din:                    in  std_logic;     
	  mux_mode:               in  std_logic;     
	  locked:                 out std_logic;     
	  chan1_en:               out std_logic;     
	  audio1:                 out std_logic_vector(23 downto 0);
	  valid1:                 out std_logic; 
	  user1:                  out std_logic; 
	  cs1:                    out std_logic; 
	  chan2_en:               out std_logic; 
	  audio2:                 out std_logic_vector(23 downto 0);
	  valid2:                 out std_logic;   
	  user2:                  out std_logic;   
	  cs2:                    out std_logic;   
	  parity_err:             out std_logic;   
	  frames:                 out std_logic_vector(7 downto 0);
	  frame0:                 out std_logic);
	end component;
	
	component aes_rx_rate_detect
	 generic (
		  CNTR_WIDTH:             integer := 14;      
		  CMP_VAL_LSB:            integer := 6;       
		  CLOCK_FREQUENCY:        integer := 133333333;
		  JITTER_ALLOWANCE:       integer := 1);       
	 port (
		  clk:                    in  std_logic;       
		  rst:                    in  std_logic;       
		  strobe:                 in  std_logic;       
		  detect:                 out std_logic;       
		  rate:                   out std_logic_vector(3 downto 0));
	end component;
	
	component samples2fifo is
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
	end component;

constant counter_modulo : integer := CLOCK_FREQUENCY/1_000_000 ; -- counting at 1Mhz


-- AES receiver signals
subtype aes_audio_sample_type is std_logic_vector(23 downto 0);
subtype aes_frame_counter_type is std_logic_vector(7 downto 0);
subtype aes_rate_type is std_logic_vector(3 downto 0);

type aes_audio_sample_type_array is array(nb_aes_channel-1 downto 0) of aes_audio_sample_type;
type aes_frame_counter_type_array is array(nb_aes_channel-1 downto 0) of aes_frame_counter_type ;
type aes_rate_type_array is array(nb_aes_channel-1 downto 0) of aes_rate_type ;

-- AES Rx #1 signals 
signal parity_err :        std_logic_vector(nb_aes_channel-1 downto 0);                      -- parity err signal
signal err_capture :       std_logic_vector(nb_aes_channel-1 downto 0);                      -- parity err capture FF
signal err_cap_rst :        std_logic_vector(nb_aes_channel-1 downto 0);                      -- error capture reset
signal aes1_locked :        std_logic_vector(nb_aes_channel-1 downto 0);                      -- Rx locked
signal channel1 :           std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 1 enable
signal channel2 :           std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 2 enable
signal audio1_out :         aes_audio_sample_type_array;          -- ch 1 audio data
signal audio2_out :         aes_audio_sample_type_array;          -- ch 2 audio data
signal valid1_out :         std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 1 valid bit
signal valid2_out :         std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 2 valid bit
signal user1_out :          std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 1 user bit
signal user2_out :          std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 2 user bit
signal cs1_out :            std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 1 ch status
signal cs2_out :            std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 2 ch status
signal aes_frame_count :   aes_frame_counter_type_array;         -- frame counter
signal aes_frame0 :         std_logic_vector(nb_aes_channel-1 downto 0);                      -- 1 = first frame
signal cs1_crc_out :        std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 1 C CRC bit
signal cs1_crc_out_en :     std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 1 C CRC enable
signal cs1_crc_err :        std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 1 C CRC err capture
signal cs1_crc_err_det :    std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 1 C CRC err detect
signal cs2_crc_out :        std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 2 C CRC bit
signal cs2_crc_out_en :     std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 2 C CRC enable
signal cs2_crc_err :        std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 2 C CRC err capture
signal cs2_crc_err_det :    std_logic_vector(nb_aes_channel-1 downto 0);                      -- ch 2 C CRC err detect
signal rate_detect :        std_logic_vector(nb_aes_channel-1 downto 0);                      -- 1 if valid AES rate
signal rate :               aes_rate_type_array;                  -- detected AES rate

signal sample_valid : std_logic_vector(nb_aes_channel-1 downto 0) ;
signal frame_info : slv16_array(nb_aes_channel-1 downto 0);
signal timestamp : std_logic_vector(31 downto 0);
signal modulo_counter : std_logic_vector(7 downto 0); -- maybe a bit oversized ...
begin

-- timestamp counter
process(gls_clk, audio_reset)
begin
	if audio_reset = '1' then
		modulo_counter <= (others => '0');
		timestamp <= (others => '0');
	elsif gls_clk'event and gls_clk = '1' then
		if modulo_counter = (counter_modulo - 1) then
			modulo_counter <= (others => '0');
			timestamp <= timestamp + 1 ;
		else
			modulo_counter <= modulo_counter + 1 ;
		end if ;
	end if ;
end process ;




generate_receivers : for i in 0 to nb_aes_channel-1 generate
		 AESRXi : aes_rx
		 port map (
			  clk                 => gls_clk,
			  rst                 => gls_reset,
			  din                 => aes_rx_input(i),
			  mux_mode            => '1', -- muxed mode
			  locked              => aes1_locked(i),
			  chan1_en            => channel1(i),
			  audio1              => audio1_out(i),
			  valid1              => valid1_out(i),
			  user1               => user1_out(i),
			  cs1                 => cs1_out(i),
			  chan2_en            => channel2(i),
			  audio2              => audio2_out(i),
			  valid2              => valid2_out(i),
			  user2               => user2_out(i),
			  cs2                 => cs2_out(i),
			  parity_err          => parity_err(i),
			  frames              => aes_frame_count(i),
			  frame0              => aes_frame0(i));


		err_cap_rst(i) <=  audio_reset ;
		flag_register(i)(13 downto 0) <= parity_err(i) & aes1_locked(i) & rate(i) & aes_frame_count(i);

		 process(audio_clk, err_cap_rst)
		 begin
			  if err_cap_rst(i) = '1' then
					err_capture(i) <= '0';
			  elsif rising_edge(audio_clk) then
					if channel2(i) = '1' and parity_err(i) = '1' then
						 err_capture(i) <= '1';
					end if;
			  end if;
		 end process;

		 RDET_i : aes_rx_rate_detect
		 generic map (
			  CLOCK_FREQUENCY     => CLOCK_FREQUENCY,
			  CMP_VAL_LSB         => CMP_VAL_LSB,
			  JITTER_ALLOWANCE    => JITTER_ALLOWANCE)
		 port map (
			  clk                 => gls_clk,
			  rst                 => gls_reset,
			  strobe              => channel2(i),
			  detect              => rate_detect(i),
			  rate                => rate(i));

		 frame_info(i)(3 downto 0) <= rate(i) ;
		 sample_valid(i) <= channel2(i) OR channel1(i) ;
		 
		 
			samples_to_fifo_i : samples2fifo
				port map (
					clk  => audio_clk,
					rst  => audio_reset, -- controled through register to guarantuee alignement of data on frame

					frame0 => aes_frame0(i) ,

					frame_info => frame_info(i) ,
					timestamp => timestamp,
					data		  => audio2_out(i),
					data_valid => sample_valid(i),

					fifo_write => fifo_wr(i),
					fifo_data => fifo_data(i),
					fifo_full => fifo_full(i)
			);
end generate ;
end Behavioral;

