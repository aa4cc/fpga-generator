library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
entity uart_tx is
generic (
DATA_BITS : integer := 8;
STOP_BITS : integer := 1;
UART_BAUD_RATE : integer := 230400;
TARGET_MCLK : integer := 50000000);
 
port (
      clock : in std_logic;
      start : in std_logic;
      data  : in std_logic_vector(DATA_BITS-1 downto 0);
      trx   : out std_logic;
		ready : out std_logic
  );
 
end uart_tx;  
 
architecture tx1 of uart_tx is
    type tx_states_t is (tx_ready, tx_start_bit, tx_data_bit, tx_stop_bit);  
        
constant BAUD_CONST : integer := TARGET_MCLK / (UART_BAUD_RATE-1);
 
signal tx_state : tx_states_t := tx_ready;
signal tx_br_cntr : integer range 0 to TARGET_MCLK / (UART_BAUD_RATE-1);
signal tx_bit_cntr : integer range 0 to DATA_BITS := DATA_BITS;
signal tx_stop_cntr : integer range 0 to STOP_BITS := STOP_BITS;

signal bit_clock : std_logic := '0';
 
 
 
begin
  
transmit : process(clock) is
  begin

  if rising_edge(clock) then
      
		ready <= '0';
		
      case tx_state is
        
        when tx_ready =>
			 ready <= '1';
			 trx <= '1';
          if start = '1' then
            tx_state <= tx_start_bit;
            tx_br_cntr <= BAUD_CONST;
            bit_clock <= not bit_clock;
            trx <= '0';
          end if;
          
        when tx_start_bit =>
          if tx_br_cntr = 0 then
              tx_state <= tx_data_bit;
				  tx_bit_cntr <= DATA_BITS;
          else
              tx_br_cntr <= tx_br_cntr - 1;
          end if;
          
        when tx_data_bit =>
          if tx_br_cntr = 0 then
            if tx_bit_cntr = 0 then 
              tx_state <= tx_stop_bit;
				  trx <= '1';
              tx_br_cntr <= BAUD_CONST;
            else
              bit_clock <= not bit_clock;
              trx <= data(DATA_BITS - tx_bit_cntr);
              tx_br_cntr <= BAUD_CONST;
              tx_bit_cntr <= tx_bit_cntr - 1;
            end if;
 
          else
            tx_br_cntr <= tx_br_cntr - 1;
          end if;
            
            
        when tx_stop_bit =>
          if tx_br_cntr = 0 then
				  tx_state <= tx_ready;
          else
            tx_br_cntr <= tx_br_cntr - 1;
          end if;
          
          
          
      
  
              
    
 
    end case;
  end if;
  end process transmit;
end tx1;
 
 
 
 