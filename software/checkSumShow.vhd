library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
entity CheckSumShow is
port (
     clock : in std_logic;
	  chan_stop : in std_logic;
	  chan_configupdate : in std_logic;
	  indicate_stop : out std_logic;
	  indicate_correct : out std_logic
	  );
end CheckSumShow;
 
architecture rtl of CheckSumShow is

 
begin
 
deelay : process(clock) is
  variable counter : integer range 0 to 50000000 := 0;
  variable stopVal : std_logic := '0';
  variable configVal : std_logic := '1';

  begin
  
  if rising_edge(clock) then
		
		if chan_stop = '1' then
			--counter := 10000000;
			counter := 500000;
			stopVal := chan_stop;
			configVal := chan_configupdate;
		end if;
		
		if counter > 0 then
			indicate_stop <= stopVal;
			indicate_correct <= configVal;
			counter := counter - 1;
		else
			indicate_stop <= '0';
			indicate_correct <= '0';
		end if;
		
  end if;
  
  end process deelay;

  
end rtl;