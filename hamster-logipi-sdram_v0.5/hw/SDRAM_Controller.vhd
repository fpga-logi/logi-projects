----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Create Date:    14:09:12 09/15/2013 
-- Module Name:    SDRAM_Controller - Behavioral 
-- Description:    Simple SDRAM controller for a Micron 48LC16M16A2-7E
--                 or Micron 48LC4M16A2-7E @ 100MHz      
-- Revision: 
-- Revision 0.1 - Initial version
-- Revision 0.2 - Removed second clock signal that isn't needed.
-- Revision 0.3 - Added back-to-back reads and writes.
-- Additional Comments: 
--
-- Performance is about
-- Writes 16 cycles = 6,250,000 writes/sec = 25.0MB/s (excluding refresh)
-- Reads  17 cycles = 5,882,352 reads/sec  = 23.5MB/s (excluding refresh)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use IEEE.NUMERIC_STD.ALL;


entity SDRAM_Controller is
    generic (
      sdram_address_width : natural;
      sdram_column_bits   : natural;
      sdram_startup_cycles: natural;
      cycles_per_refresh  : natural
    );
    Port ( clk           : in  STD_LOGIC;
           reset         : in  STD_LOGIC;
           
           -- Interface to issue reads or write data
           cmd_ready         : out STD_LOGIC;                     -- '1' when a new command will be acted on
           cmd_enable        : in  STD_LOGIC;                     -- Set to '1' to issue new command (only acted on when cmd_read = '1')
           cmd_wr            : in  STD_LOGIC;                     -- Is this a write?
           cmd_address       : in  STD_LOGIC_VECTOR(sdram_address_width-2 downto 0); -- address to read/write
           cmd_byte_enable   : in  STD_LOGIC_VECTOR(3 downto 0);  -- byte masks for the write command
           cmd_data_in       : in  STD_LOGIC_VECTOR(31 downto 0); -- data for the write command
           
           data_out          : out STD_LOGIC_VECTOR(31 downto 0); -- word read from SDRAM
           data_out_ready    : out STD_LOGIC;                     -- is new data ready?
           
           -- SDRAM signals
           SDRAM_CLK     : out   STD_LOGIC;
           SDRAM_CKE     : out   STD_LOGIC;
           SDRAM_CS      : out   STD_LOGIC;
           SDRAM_RAS     : out   STD_LOGIC;
           SDRAM_CAS     : out   STD_LOGIC;
           SDRAM_WE      : out   STD_LOGIC;
           SDRAM_DQM     : out   STD_LOGIC_VECTOR( 1 downto 0);
           SDRAM_ADDR    : out   STD_LOGIC_VECTOR(12 downto 0);
           SDRAM_BA      : out   STD_LOGIC_VECTOR( 1 downto 0);
           SDRAM_DATA    : inout STD_LOGIC_VECTOR(15 downto 0));
end SDRAM_Controller;

architecture Behavioral of SDRAM_Controller is
   -- From page 37 of MT48LC16M16A2 datasheet
   -- Name (Function)       CS# RAS# CAS# WE# DQM  Addr    Data
   -- COMMAND INHIBIT (NOP)  H   X    X    X   X     X       X
   -- NO OPERATION (NOP)     L   H    H    H   X     X       X
   -- ACTIVE                 L   L    H    H   X  Bank/row   X
   -- READ                   L   H    L    H  L/H Bank/col   X
   -- WRITE                  L   H    L    L  L/H Bank/col Valid
   -- BURST TERMINATE        L   H    H    L   X     X     Active
   -- PRECHARGE              L   L    H    L   X   Code      X
   -- AUTO REFRESH           L   L    L    H   X     X       X 
   -- LOAD MODE REGISTER     L   L    L    L   X  Op-code    X 
   -- Write enable           X   X    X    X   L     X     Active
   -- Write inhibit          X   X    X    X   H     X     High-Z

   -- Here are the commands mapped to constants   
   constant CMD_UNSELECTED    : std_logic_vector(3 downto 0) := "1000";
   constant CMD_NOP           : std_logic_vector(3 downto 0) := "0111";
   constant CMD_ACTIVE        : std_logic_vector(3 downto 0) := "0011";
   constant CMD_READ          : std_logic_vector(3 downto 0) := "0101";
   constant CMD_WRITE         : std_logic_vector(3 downto 0) := "0100";
   constant CMD_TERMINATE     : std_logic_vector(3 downto 0) := "0110";
   constant CMD_PRECHARGE     : std_logic_vector(3 downto 0) := "0010";
   constant CMD_REFRESH       : std_logic_vector(3 downto 0) := "0001";
   constant CMD_LOAD_MODE_REG : std_logic_vector(3 downto 0) := "0000";

   constant MODE_REG          : std_logic_vector(12 downto 0) := 
    -- Reserved, wr bust, OpMode, CAS Latency (2), Burst Type, Burst Length (2)
         "000" &   "0"  &  "00"  &    "010"      &     "0"    &   "001";

   signal iob_command     : std_logic_vector( 3 downto 0) := CMD_NOP;
   signal iob_address     : std_logic_vector(12 downto 0) := (others => '0');
   signal iob_data        : std_logic_vector(15 downto 0) := (others => '0');
   signal iob_dqm         : std_logic_vector( 1 downto 0) := (others => '0');
   signal iob_cke         : std_logic := '0';
   signal iob_bank        : std_logic_vector( 1 downto 0) := (others => '0');
   
   attribute IOB: string;
   attribute IOB of iob_command: signal is "true";
   attribute IOB of iob_address: signal is "true";
   attribute IOB of iob_dqm    : signal is "true";
   attribute IOB of iob_cke    : signal is "true";
   attribute IOB of iob_bank   : signal is "true";
   attribute IOB of iob_data   : signal is "true";
   
   signal captured_data      : std_logic_vector(15 downto 0) := (others => '0');
   signal captured_data_last : std_logic_vector(15 downto 0) := (others => '0');
   signal sdram_din          : std_logic_vector(15 downto 0);
   attribute IOB of captured_data : signal is "true";
   
   type fsm_state is (s_startup,
                      s_idle_in_9,   
                      s_idle_in_8,   
                      s_idle_in_7,   
                      s_idle_in_6,   
                      s_idle_in_5, s_idle_in_4,   s_idle_in_3, s_idle_in_2, s_idle_in_1,
                      s_idle,
                      s_open_in_2, s_open_in_1,
                      s_write_1, s_write_2, s_write_3,
                      s_read_1,  s_read_2,  s_read_3,  s_read_4,  
                      s_precharge
                      );

   signal state              : fsm_state := s_startup;
   signal startup_wait_count : unsigned(15 downto 0) := to_unsigned(sdram_startup_cycles,16);  -- 10100
   
   signal refresh_count   : unsigned(13 downto 0) := (others => '0');
   signal pending_refresh : std_logic := '0';
   constant refresh_max   : unsigned(13 downto 0) := to_unsigned(cycles_per_refresh,14); 
   
   signal addr_row         : std_logic_vector(12 downto 0) := (others => '0');
   signal addr_col         : std_logic_vector(12 downto 0) := (others => '0');
   signal addr_bank        : std_logic_vector( 1 downto 0) := (others => '0');
   signal dqm_sr           : std_logic_vector( 3 downto 0) := (others => '1'); -- an extra two bits in case CAS=3
   
   -- signals to hold the requested transaction
   signal save_wr          : std_logic := '0';
   signal save_row         : std_logic_vector(12 downto 0);
   signal save_bank        : std_logic_vector( 1 downto 0);
   signal save_col         : std_logic_vector(12 downto 0);
   signal save_d_in        : std_logic_vector(31 downto 0);
   signal save_byte_enable : std_logic_vector( 3 downto 0);

   signal opened_row         : std_logic_vector(12 downto 0);
   signal opened_bank        : std_logic_vector( 1 downto 0);
   
   signal iob_dq_hiz     : std_logic := '1';

   -- signals for when to read the data off of the bus
   signal data_ready_delay : std_logic_vector( 4 downto 0);
   
   signal ready_for_new   : std_logic := '0';
   signal got_transaction : std_logic := '0';
   
   constant start_of_col  : natural := 0;
   constant end_of_col    : natural := sdram_column_bits-2;
   constant start_of_bank : natural := sdram_column_bits-1;
   constant end_of_bank   : natural := sdram_column_bits;
   constant start_of_row  : natural := sdram_column_bits+1;
   constant end_of_row    : natural := sdram_address_width-2;
begin
   -- tell the outside world when we can accept a new transaction;
   cmd_ready <= ready_for_new;

   ----------------------------------------------------------------------------
   -- Seperate the address into row / bank / address
   ----------------------------------------------------------------------------
   addr_row(end_of_row-start_of_row downto 0)   <= cmd_address(end_of_row  downto start_of_row);  
   addr_bank                                    <= cmd_address(end_of_bank downto start_of_bank);
   addr_col(sdram_column_bits-1 downto 0)       <= cmd_address(end_of_col  downto start_of_col) & '0';    

   -----------------------------------------------------------
   -- Forward the SDRAM clock to the SDRAM chip - 180 degress 
   -- out of phase with the control signals (ensuring setup and holdup 
  -----------------------------------------------------------
 sdram_clk_forward : ODDR2
   generic map(DDR_ALIGNMENT => "NONE", INIT => '0', SRTYPE => "SYNC")
   port map (Q => sdram_clk, C0 => clk, C1 => not clk, CE => '1', R => '0', S => '0', D0 => '0', D1 => '1');

   -----------------------------------------------
   --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   --!! Ensure that all outputs are registered. !!
   --!! Check the pinout report to be sure      !!
   --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   -----------------------------------------------
   sdram_cke  <= iob_cke;
   sdram_CS   <= iob_command(3);
   sdram_RAS  <= iob_command(2);
   sdram_CAS  <= iob_command(1);
   sdram_WE   <= iob_command(0);
   sdram_dqm  <= iob_dqm;
   sdram_ba   <= iob_bank;
   sdram_addr <= iob_address;
   
iob_dq_g: for i in 0 to 15 generate
   begin
iob_dq_iob: IOBUF
   generic map (DRIVE => 12, IOSTANDARD => "LVTTL", SLEW => "FAST")
   port map ( O  => sdram_din(i),   -- Buffer output
              IO => sdram_data(i),  -- Buffer inout port (connect directly to top-level port)
              I  => iob_data(i),    -- Buffer input
              T  => iob_dq_hiz      -- 3-state enable input, high=input, low=output 
   );
end generate;
   
                                                 
capture_proc: process(clk) 
   begin
     if rising_edge(clk) then
         captured_data      <= sdram_din;
      end if;
   end process;
   

main_proc: process(clk) 
   begin
      if rising_edge(clk) then
         captured_data_last <= captured_data;
      
         ------------------------------------------------
         -- Default state is to do nothing
         ------------------------------------------------
         iob_command     <= CMD_NOP;
         iob_address     <= (others => '0');
         iob_bank        <= (others => '0');

         -- countdown for initialisation
         startup_wait_count <= startup_wait_count-1;
         
         -- Logic to decide when to refresh
         if refresh_count /= refresh_max then
            refresh_count <= refresh_count + 1;
         else
            refresh_count <= (others => '0');
            if state /= s_startup then
               pending_refresh <= '1';
            end if;
         end if;
         
         ---------------------------------------------
         -- It we are ready for a new tranasction 
         -- and one is being presented, then accept it
         -- remember what we are reading or writing
         ---------------------------------------------
         if ready_for_new = '1' and cmd_enable = '1' then
            save_row         <= addr_row;
            save_bank        <= addr_bank;
            save_col         <= addr_col;
            save_wr          <= cmd_wr; 
            save_d_in        <= cmd_data_in;
            save_byte_enable <= cmd_byte_enable;
            got_transaction  <= '1';
            ready_for_new    <= '0';
         end if;

         ------------------------------------------------
         -- Handle the data coming back from the 
         -- SDRAM for the Read transaction
         ------------------------------------------------
         data_out_ready <= '0';
         if data_ready_delay(0) = '1' then
            data_out <= captured_data & captured_data_last;
            data_out_ready <= '1';
         end if;
         -- update shift registers used to choose when to present data from memory
         data_ready_delay <= '0' & data_ready_delay(data_ready_delay'high downto 1);
         iob_dqm <= dqm_sr(1 downto 0);
         dqm_sr <= "11" & dqm_sr(dqm_sr'high downto 2);
         
         case state is 
            when s_startup =>
               ------------------------------------------------------------------------
               -- This is the initial startup state, where we wait for at least 100us
               -- before starting the start sequence
               -- 
               -- The initialisation is sequence is 
               --  * de-assert SDRAM_CKE
               --  * 100us wait, 
               --  * assert SDRAM_CKE
               --  * wait at least one cycle, 
               --  * PRECHARGE
               --  * wait 2 cycles
               --  * REFRESH, 
               --  * tREF wait
               --  * REFRESH, 
               --  * tREF wait 
               --  * LOAD_MODE_REG 
               --  * 2 cycles wait
               ------------------------------------------------------------------------
                  iob_CKE <= '1';
               
               if startup_wait_count = 21 then      
                   -- ensure all rows are closed
                  iob_command     <= CMD_PRECHARGE;
                  iob_address(10) <= '1';  -- all banks
                  iob_bank        <= (others => '0');
               elsif startup_wait_count = 18 then   
                  -- these refreshes need to be at least tREF (66ns) apart
                  iob_command     <= CMD_REFRESH;
               elsif startup_wait_count = 11 then
                  iob_command     <= CMD_REFRESH;
               elsif startup_wait_count = 4 then    
                  -- Now load the mode register
                  iob_command     <= CMD_LOAD_MODE_REG;
                  iob_address     <= MODE_REG;
               else
                  iob_command     <= CMD_NOP;
               end if;

               pending_refresh    <= '0';

               if startup_wait_count = 0 then
                  state           <= s_idle;
                  ready_for_new   <= '1';
                  got_transaction <= '0';
               end if;
            when s_idle_in_9 => state <= s_idle_in_8;
            when s_idle_in_8 => state <= s_idle_in_7;
            when s_idle_in_7 => state <= s_idle_in_6;
            when s_idle_in_6 => state <= s_idle_in_5;
            when s_idle_in_5 => state <= s_idle_in_4;
            when s_idle_in_4 => state <= s_idle_in_3;
            when s_idle_in_3 => state <= s_idle_in_2;
            when s_idle_in_2 => state <= s_idle_in_1;
            when s_idle_in_1 => state <= s_idle;

            when s_idle =>
               -- Priority is to issue a refresh if one is outstanding
               if pending_refresh = '1' then
                 ------------------------------------------------------------------------
                  -- Start the refresh cycle. 
                  -- This tasks tRFC (66ns), so 6 idle cycles are needed @ 100MHz
                  ------------------------------------------------------------------------
                  state            <= s_idle_in_6;
                  iob_command      <= CMD_REFRESH;
                  pending_refresh  <= '0';
               elsif got_transaction = '1' then
                  --------------------------------
                  -- Start the read or write cycle. 
                  -- First task is to open the row
                  --------------------------------
                  state       <= s_open_in_2;
                  iob_command <= CMD_ACTIVE;
                  iob_address <= save_row;
                  iob_bank    <= save_bank;
                  opened_row  <= save_row;
                  opened_bank <= save_bank;
               end if;               
            ------------------------------------------
            -- Opening the row ready for read or write
            ------------------------------------------
            when s_open_in_2 => state <= s_open_in_1;

            when s_open_in_1 =>
               -- still waiting for row to open
               if save_wr = '1' then
                  state              <= s_write_1;
                  iob_dq_hiz         <= '0';
                  iob_data           <= save_d_in(15 downto 0); -- get the DQ bus out of HiZ early
               else
                  iob_dq_hiz         <= '1';
                  state              <= s_read_1;
                  ready_for_new      <= '1'; -- we will be ready for a new transaction next cycle!
                  got_transaction    <= '0';                  
               end if;

            ----------------------------------
            -- Processing the read transaction
            ----------------------------------
            when s_read_1 =>
               state              <= s_read_2;
               iob_command     <= CMD_READ;
               iob_address     <= save_col; 
               iob_address(10) <= '0'; -- A10 actually matters - it selects auto precharge
               iob_bank        <= save_bank;
               
               -- Schedule reading the data values off the bus
               data_ready_delay(data_ready_delay'high)   <= '1';
               
               -- Set the data masks to read all bytes
               iob_dqm            <= (others => '0');    -- For CAS = 2
               dqm_sr(1 downto 0) <= (others => '0');   -- For CAS = 2 or CAS = 3
               -- dqm_sr(3 downto 2) <= (others => '0');   -- CAS = 3
            when s_read_2 =>
               state <= s_read_3;
               if pending_refresh = '0' and got_transaction = '1' and save_bank = opened_bank and save_row = opened_row and save_wr = '0' then
                  state <= s_read_1;
                  ready_for_new      <= '1'; -- we will be ready for a new transaction next cycle!
               end if;
            when s_read_3 => 
               state <= s_read_4;
               if pending_refresh = '0' and got_transaction = '1' and save_bank = opened_bank and save_row = opened_row and save_wr = '0' then
                  state <= s_read_1;
                  ready_for_new      <= '1'; -- we will be ready for a new transaction next cycle!
               end if;

            when s_read_4 => 
               state <= s_precharge;
               -- can we do back-to-back read?
               if pending_refresh = '0' and got_transaction = '1' and save_bank = opened_bank and save_row = opened_row then
                  if save_wr = '0' then
                     state <= s_read_1;
                     ready_for_new   <= '1'; -- we will be ready for a new transaction next cycle!
                  else
                     state <= s_open_in_2;
                  end if;
               end if;

            ------------------------------------------------------------------
            -- Processing the write transaction
            -------------------------------------------------------------------
            when s_write_1 =>
               state              <= s_write_2;
               iob_command        <= CMD_WRITE;
               iob_address        <= save_col; 
               iob_address(10)    <= '0'; -- A10 actually matters - it selects auto precharge
               iob_bank           <= save_bank;
               iob_dqm            <= NOT save_byte_enable(1 downto 0);    
               dqm_sr(1 downto 0) <= NOT save_byte_enable(3 downto 2);    
               iob_data           <= save_d_in(15 downto 0);
               ready_for_new      <= '1';
               got_transaction    <= '0';
            when s_write_2 =>
               state           <= s_write_3;
               iob_data        <= save_d_in(31 downto 16);
               -- can we do a back-to-back write?
               if pending_refresh = '0' and got_transaction = '1' and save_bank = opened_bank and save_row = opened_row then
                  if save_wr = '1' then
                     -- back-to-back write?
                     state           <= s_write_1;
                  else
                     -- write-to-read switch?
                     state           <= s_read_1;
                     iob_dq_hiz      <= '1';
                     ready_for_new   <= '1'; -- we will be ready for a new transaction next cycle!
                     got_transaction <= '0';                  
                  end if;
               end if;
         
            when s_write_3 =>  -- must wait tRDL, hence the extra idle state
               -- back to back transaction?
               if pending_refresh = '0' and got_transaction = '1' and save_bank = opened_bank and save_row = opened_row then
                  if save_wr = '1' then
                     -- back-to-back write?
                     state           <= s_write_1;
                  else
                     -- write-to-read switch?
                     state           <= s_read_1;
                     iob_dq_hiz      <= '1';
                     ready_for_new   <= '1'; -- we will be ready for a new transaction next cycle!
                     got_transaction <= '0';                  
                  end if;
               else
                  iob_dq_hiz         <= '1';
                  state              <= s_precharge;
               end if;

            -------------------------------------------------------------------
            -- Closing the row off (this closes all banks)
            -------------------------------------------------------------------
            when s_precharge =>
               state           <= s_idle_in_9;
               iob_command     <= CMD_PRECHARGE;
               iob_address(10) <= '1'; -- A10 actually matters - it selects all banks or just one

            -------------------------------------------------------------------
            -- We should never get here, but if we do then reset the memory
            -------------------------------------------------------------------
            when others => 
               state <= s_startup;
               ready_for_new       <= '0';
               pending_refresh     <= '0';
               startup_wait_count  <= to_unsigned(sdram_startup_cycles,16);
         end case;
         
         -- Sync reset
         if reset = '1' then
            state               <= s_startup;
            ready_for_new       <= '0';
            pending_refresh     <= '0';
            startup_wait_count  <= to_unsigned(sdram_startup_cycles,16);
         end if;
      end if;      
   end process;
end Behavioral;