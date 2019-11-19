
LIBRARY ieee;
USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

ENTITY ComDecoder IS 
	PORT
	(
		CLK : in std_logic;
		byte_in : in std_logic_vector(7 downto 0);

		byte_in_valid : in std_logic;
		bit_out : out std_logic;
		bit_out_shift : out std_logic;
		selector : out std_logic;
		pll_scanclkena : out std_logic;
		pll_configupdate : out std_logic;
		chan_stop  : out std_logic;
		chan_configupdate : out std_logic;
		debug :	out std_logic_vector(7 downto 0)
		
	);
END ComDecoder;

architecture arch1 of ComDecoder is

signal possibleCode : std_logic_vector(23 downto 0);

constant CODE_CHANNELS_START : std_logic_vector(23 downto 0) := "111111111111111111110000";
constant CODE_CHANNELS_STOP  : std_logic_vector(23 downto 0) := "111111111111111111110001";
constant CODE_PLL_START  : std_logic_vector(23 downto 0) := "111111111111111111110010";
constant CODE_PLL_STOP  : std_logic_vector(23 downto 0) := "111111111111111111110011";


signal passByteOn : std_logic := '0';
signal byteToBePassed : std_logic_vector(7 downto 0) := "00000000";

signal blockBytes : integer range 0 to 3 := 0;
signal numberEnabled : std_logic := '0';

signal bitOutShiftSig : std_logic := '0';

signal recCodeChanStop : std_logic := '0';
signal recCodePllStop : std_logic := '0';
signal recSumOk : std_logic := '0';

signal selectorSig : std_logic := '0';

signal clkenaSig : std_logic := '0';
signal configSig : std_logic := '0';



signal debugSig : std_logic_vector(7 downto 0) := "00000000";


begin

debug <= debugSig(7 downto 0);
bit_out_shift <= bitOutShiftSig and numberEnabled;

selector <= selectorSig;

pll_scanclkena <= clkenaSig;


 decode : process(CLK) is
 --scan incoming bytes for codes
  variable lastValid : std_logic := '0';
  variable varCode : std_logic_vector(23 downto 0) := (others => '0');
  
  variable byteIsNotCode : std_logic := '0';
  variable byteIsNotCodeDeelayed : std_logic := '0';
  variable numberEnabledVar : std_logic := '0';
  
  
  variable lastPassed : std_logic_vector(7 downto 0) := (others => '0');
  
  variable configCountdown : integer range -2 to 13 := -2;
  
  variable blockSummation : integer range -2 to 13 := 0;
  
  
  constant ZERO : std_logic_vector(15 downto 0) := (others => '0');
  
  
  variable bytesReceived : integer range -1 to 150 := 0;
  variable receivingState : std_logic := '0';
  variable incomingSumBytes : integer range -2 to 13 := 0;
  
  variable controlSumCalculated : std_logic_vector(15 downto 0) := (others => '0');
  variable controlSumReceived : std_logic_vector(15 downto 0) := (others => '0');
  variable performSumCheck : std_logic := '0';   
  
  
  
  begin
  
  if rising_edge(CLK) then
		
		configSig <= '0';
		clkenaSig <= '1';
		
		debugSig <= controlSumReceived(7 downto 0);
		
		
		
		if byte_in_valid = '1' and lastValid = '0' then
			
			if incomingSumBytes > 0 then
				
				varCode := (others => '0');
			
				controlSumReceived := controlSumReceived(7 downto 0) & byte_in;
				incomingSumBytes := incomingSumBytes - 1;
				
				if incomingSumBytes = 0 then
					recCodeChanStop <= '1';
					
					if controlSumReceived = controlSumCalculated then
						recSumOk  <= '1';
					else
						recSumOk <= '0';
					end if;
					
				end if;
				
			else
			
			
				byteToBePassed <= varCode(23 downto 16); --shift last out
				
				lastPassed := varCode(23 downto 16);
				
				byteIsNotCode := '1';
				
				numberEnabled <= numberEnabledVar;
				
				
				varCode := varCode(15 downto 0) & byte_in; --shift new one in
				
				if varCode = CODE_CHANNELS_START then
					numberEnabledVar := '1';
					byteIsNotCode := '0';	
					selectorSig <= '0';
					blockSummation := 3;
					
				end if;
				
				recCodeChanStop <= '0';
				
				if varCode = CODE_CHANNELS_STOP then
					numberEnabledVar := '0';
					byteIsNotCode := '0';
					--blockSummation := 3;
					incomingSumBytes := 2;
				end if;
				
				if varCode = CODE_PLL_START then
					numberEnabledVar := '1';
					byteIsNotCode := '0';
					selectorSig <= '1';
					blockSummation := 3;
				end if;
				
				if varCode = CODE_PLL_STOP then
					recCodePllStop <= '1';
					numberEnabledVar := '0';
					byteIsNotCode := '0';
					--blockSummation := 3;
				else
					recCodePllStop <= '0';
				end if;
			
				passByteOn <= '1';
				
				if byteIsNotCodeDeelayed = '0' then
					--is code, block next 3 bytes from passing into stream.
					blockBytes <= 3;
				else
					blockBytes <= 0;
				end if;
				
				byteIsNotCodeDeelayed := byteIsNotCode;
				
				
				
		
		
				if (varCode = CODE_CHANNELS_START) then
					controlSumCalculated := (others => '0');
				end if;
					
					
				if numberEnabledVar = '1' and blockSummation = 0 then
					controlSumCalculated := controlSumCalculated + varCode(23 downto 16);
				end if;
				
				if blockSummation > 0 then
					blockSummation := blockSummation - 1;
				end if;
	
				
	--			
	--			if varCode = CODE_CHANNELS_START then
	--				controlSum <= (others => '0');
	--			elsif varCode /= CODE_CHANNELS_STOP then
	--				controlSum(7 downto 0) <= varCode(23 downto 16);
	--			end if;
	
				
				
			end if;	
		
		else
			--chan_stop <= '0';
			recCodeChanStop <= '0';
			recSumOk <= '0';
			passByteOn <= '0';
		end if;
	
		lastValid := byte_in_valid;

  end if;
 
  end process decode;
  
  deelay : process(CLK) is
  --deelay STOP signal transmission to allow passByte to shift data before channels latch it
  variable deelayVectorChanStop : std_logic_vector(15 downto 0) :="0000000000000000";
  variable deelayVecotrSumOk : std_logic_vector(15 downto 0) := "0000000000000000";
  variable deelayVectorPllStop : std_logic_vector(15 downto 0) :="0000000000000000";

  begin
  if rising_edge(CLK) then
		chan_stop <= deelayVectorChanStop(15);
		pll_configupdate <= deelayVectorPllStop(15);
		chan_configupdate <= deelayVecotrSumOk(15);
		deelayVectorChanStop := deelayVectorChanStop(14 downto 0) & recCodeChanStop;
		deelayVecotrSumOk := deelayVecotrSumOk(14 downto 0) & recSumOk;
		deelayVectorPllStop := deelayVectorPllStop(14 downto 0) & recCodePllStop;
  end if;
  end process deelay;
  
  
 passByte : process(CLK) is
  --shift non-code bytes into shiftreg
  variable lastPass : std_logic := '0';
  variable bitCounter : integer range 0 to 8 := 0;
  variable downTime : std_logic := '0';
  variable latchedByte : std_logic_vector(7 downto 0) := "00000000";
  variable latchedBlock : integer range 0 to 3 := 0;

  
  begin
  
  if rising_edge(CLK) then
  
 
		
		
		
		
		if passByteOn = '1' and lastPass = '0' then
			
			if latchedBlock = 0 then
				latchedBlock := blockBytes;
			end if;
			
			if latchedBlock > 0 then
				latchedBlock := latchedBlock -1;
			else
				bitCounter := 8;
				latchedByte := byteToBePassed;
			end if;
		end if;
		
		if bitCounter > 0 then
			if downTime = '1' then
				bitOutShiftSig <= '0';
				downTime := '0';
			else
				bit_out <= latchedByte(8 - bitCounter);
				bitOutShiftSig <= '1';
				bitCounter := bitCounter - 1;
				downTime := '1';
			end if;
		end if;
		
		lastPass := passByteOn;
  
  end if;
  
  end process passByte;
  
  
  
end arch1;

