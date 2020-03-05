library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
entity TristateDemux is
port (
     input : in std_logic; 
	  selector : in std_logic;
	  outWhen0 : out std_logic;
	  outWhen1 : out std_logic
	  );
end TristateDemux;
 
architecture rtl of TristateDemux is

 
begin
 
 outWhen0 <= input when selector = '0' else 'Z';
 outWhen1 <= input when selector = '1' else 'Z';
 
  
end rtl;