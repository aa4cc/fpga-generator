library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity bidir_interface1  is
    port (
		  bidir_pin : inout std_logic;
        sig_use : out  std_logic;
		  sig_in : in std_logic;
        is_master : in std_logic
    );
end bidir_interface1;
 
architecture arch of bidir_interface1 is

begin
    
	 bidir_pin <= '0' when (is_master = '1' and sig_in = '0') else 'Z';
	 sig_use <= bidir_pin;
	  
end arch;
