library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
entity Mux is
port (
     inWhen0 : in std_logic; 
     inWhen1 : in std_logic; 
	  selector : in std_logic;
	  output : out std_logic
	  );
end Mux;
 
architecture rtl of Mux is

 
begin
 
 output <= inWhen0 when selector = '0' else inWhen1; 

  
end rtl;