library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity outClockEnable  is
    port (
		  clock_in : in std_logic;
        is_master : in  std_logic;
		  out_enable : in std_logic;
        clock_out : out std_logic
    );
end outClockEnable;
 
architecture arch of outClockEnable is

begin
    
	 clock_out <= clock_in when (is_master = '1' and out_enable = '1') else '0';
	  
end arch;
