library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity tristate_test  is
    port (
		  bidir_pin : inout std_logic;
        read_from_bidir : out  std_logic;
		  data_in : in std_logic;
        output_en : in std_logic
    );
end tristate_test;
 
architecture arch of tristate_test is
    signal temp: std_logic := '0'; 
    signal counter : integer range 0 to 50000000 := 0;
begin
    
	 read_from_bidir <= bidir_pin;
	 bidir_pin <= data_in when output_en = '1' else 'Z';
	 
end arch;
