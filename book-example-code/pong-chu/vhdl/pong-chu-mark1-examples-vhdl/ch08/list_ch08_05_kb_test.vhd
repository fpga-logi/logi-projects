-- Listing 8.5
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity kb_test is
   port (
      clk, reset: in  std_logic;
      ps2d, ps2c: in  std_logic;
      tx: out  std_logic
   );
end kb_test;

architecture arch of kb_test is
   signal scan_data, w_data: std_logic_vector(7 downto 0);
   signal kb_not_empty, kb_buf_empty: std_logic;
   signal key_code, ascii_code: std_logic_vector(7 downto 0);
begin
   kb_code_unit: entity work.kb_code(arch)
      port map(clk=>clk, reset=>reset, ps2d=>ps2d, ps2c=>ps2c,
               rd_key_code=>kb_not_empty, key_code=>key_code,
               kb_buf_empty=>kb_buf_empty);
   uart_unit: entity work.uart(str_arch)
      port map(clk=>clk, reset=>reset, rd_uart=>'0',
               wr_uart=>kb_not_empty, rx=>'1',
               w_data=>ascii_code, tx_full=>open,
               rx_empty=>open, r_data=>open, tx=>tx);
   key2a_unit: entity work.key2ascii(arch)
      port map(key_code=>key_code, ascii_code=>ascii_code);

   kb_not_empty <= not kb_buf_empty;
end arch;