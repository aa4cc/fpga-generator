library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
 
entity PllReconfigurator is
port (
     clock : in std_logic;
	  performReconfig : in std_logic;
	  scanchain : in std_logic_vector(143 downto 0);
	  areset : out std_logic;
	  scanclk : out std_logic;
	  scandata : out std_logic;
	  scanclkena : out std_logic; 
	  configupdate : out std_logic
	  );
end PllReconfigurator;
 
architecture rtl of PllReconfigurator is

type states_t is (s_ready, s_shifting, s_done, s_update, s_rearm);


 
begin
 
 
 run : process(clock) is
 variable state : states_t := s_ready;
 variable keptChain : std_logic_vector(143 downto 0) := (others => '0');
 variable position : integer range 143 to 0 := 0;
 variable clkVar : std_logic := '0';
 begin
 
  if rising_edge(clock) then
	areset <= '0';
	scanclk <= '0';
	scanclkena <= '0';
	scandata <= '0';
	configupdate <= '0';
  
	case state is
		when s_ready =>
			if performReconfig = '1' then
				state := s_shifting;
				keptChain := scanchain;
				scanclkena <= '1';
				clkVar := '1';
				position := 0;
			end if;
		when s_shifting =>
			scanclkena <= '1';
			if clkVar = '0' then
				clkVar := '1';
				scanclk <= '0';
				if position = 143 then
					state := s_done;
					scanclkena <= '0';
				else
					position := position + 1;
				end if;
			else
				clkVar := '0';
				scanclk <= '1';
			end if;
			scandata <= keptChain(position);
			
			
		when s_done =>
			state := s_update;
		when s_update =>
			configupdate <= '1';
			state := s_rearm;
		when s_rearm =>
			if performReconfig = '0' then
				state := s_ready;
			end if;
	
	end case;
  
  
  
  
  end if;
 
 
 end process run;
 
 
 
  
end rtl;