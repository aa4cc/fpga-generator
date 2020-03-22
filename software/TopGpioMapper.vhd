library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity TopGpioMapper  is
    port (
		  channelsOut : in std_logic_vector(63 downto 0);
		  chainingModeOn : in std_logic;
		  gpio1 : out std_logic_vector(31 downto 0);
		  gpio2 : out std_logic_vector(31 downto 0)
    );
end TopGpioMapper;
 
architecture arch of TopGpioMapper is
    signal temp: std_logic := '0'; 
    signal counter : integer range 0 to 50000000 := 0;
begin

end arch;
