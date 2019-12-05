
LIBRARY ieee;
USE ieee.std_logic_1164.all; 
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

ENTITY CommV2 IS 
	PORT
	(
		CLK : in std_logic;
		master_in : in std_logic;
		byte_in : in std_logic_vector(7 downto 0);
		byte_in_valid : in std_logic;
		uart_ready : in std_logic;
		uart_send_byte : out std_logic_vector(7 downto 0);
		uart_send_start : out std_logic;
		chan_phases : out std_logic_vector(575 downto 0);
		chan_duties : out std_logic_vector(575 downto 0);
		
		master_clock_enable : out std_logic;
		reset : out std_logic;
		
		debug :	out std_logic_vector(7 downto 0)
	);
END CommV2; 

architecture arch1 of CommV2 is

--replies
constant R_CRC_OK : std_logic_vector(3 downto 0) := "1111";
constant R_CRC_WRONG : std_logic_vector(3 downto 0) := "0011";
constant R_GOT_TRIG : std_logic_vector(3 downto 0) := "0010";
   


constant CRC_LEN : integer := 8;
constant CRC_POLY : std_logic_vector(CRC_LEN downto 0) := "100000111"; --0x107

constant BUF_LEN : integer := 750;--1151;
signal dataBufferSig : std_logic_vector(BUF_LEN downto 0) := (others => '0');
signal crcSig : std_logic_vector(CRC_LEN-1 downto 0) := (others => '0');
signal crcDataLen : integer range 0 to BUF_LEN := 0;
signal crcRequest : std_logic := '0';
signal crcReady : std_logic := '0';


type dStates_t is (s_ready,s_gotCode, s_unknownCode, s_dataByte, s_requestCrc, s_crcByte, s_crcWaitR, s_evaluate, s_doPhases, s_doDuties, s_doInquire, s_prepSync, s_performSync, s_transmitReply);  
type cStates_t is (s_ready, s_calculating, s_shift, s_complete);

begin

debug <= crcSig;


 decode : process(CLK) is

  constant CODE_SET_PHASES : std_logic_vector(7 downto 0) 		:= "00000001";
  constant CODE_SET_DUTIES : std_logic_vector(7 downto 0) 		:= "00000010";
  constant CODE_SET_PLL : std_logic_vector(7 downto 0) 			:= "00000100";
  constant CODE_INQUIRE_MASTER : std_logic_vector(7 downto 0) 	:= "00001000";
  constant CODE_SYNC_DIVIDERS : std_logic_vector(7 downto 0) 	:= "00010000";
  
  constant REPLY_CRC_OK : std_logic_vector(3 downto 0) := "1111";
  constant REPLY_CRC_FAIL : std_logic_vector(3 downto 0) := "0000";
  
  constant REPLY_SET_PHASES : std_logic_vector(3 downto 0) := "0001";
  constant REPLY_SET_DUTIES : std_logic_vector(3 downto 0) := "0010";
  constant REPLY_SET_PLL : std_logic_vector(3 downto 0) := "0011";
  constant REPLY_I_AM_MASTER : std_logic_vector(3 downto 0) := "0100";
  constant REPLY_I_AM_SLAVE : std_logic_vector(3 downto 0)  := "0101";
  constant REPLY_SYNC_OK : std_logic_vector(3 downto 0)  := "0110";
  constant REPLY_SYNC_NOT_MASTER : std_logic_vector(3 downto 0)  := "0111";
  constant REPLY_UNKNOWN_CODE : std_logic_vector(3 downto 0)  := "1000";
  
  
  
 
  variable unitID : std_logic_vector(3 downto 0) := "0000";
  
  variable d_state : dStates_t := s_ready;
  
  variable incomingByte : std_logic_vector(7 downto 0);
  variable codeByte : std_logic_vector(7 downto 0) := (others => '0');
  variable thisValid : std_logic := '0';
  variable lastValid : std_logic := '0';
  
  variable dataBuffer : std_logic_vector(BUF_LEN downto 0) := (others => '0');
  variable byteCounter : integer range 0 to 2048 := 0;
  variable dataLen : integer range 0 to 2048 := 0;
  
  variable crcGotten : std_logic_vector(CRC_LEN - 1 downto 0) := (others => '0');
  variable crcCalced : std_logic_vector(CRC_LEN - 1 downto 0) := (others => '0');
  
  variable crcIsCorrect : std_logic := '0';
  
  variable reply : std_logic_vector(7 downto 0);
  
  variable uartAllow : std_logic := '0';
  
  variable syncCounter : integer range 0 to 10000000;
  constant resetCount : integer := 		50000;
  constant enableCount : integer := 	500000;
  
  begin
  
  if rising_edge(CLK) then
	incomingByte := byte_in;
  
	lastValid := thisValid;
	thisValid := byte_in_valid;
	
	crcRequest <= '0';
	uart_send_start <= '0';
	
	reset <= '0';
	master_clock_enable <= '1';
  
	case d_state is
	
	when s_ready =>
		if lastValid = '0' and thisValid = '1' then
			--gotten new byte!
			codeByte := incomingByte;
			d_state := s_gotCode;
			dataBuffer := (others => '0');
			uartAllow := '1';
		end if;

	when s_gotCode =>
		case codeByte is
			when CODE_SET_PHASES =>
				byteCounter := 2;
				d_state := s_dataByte;
			when CODE_SET_DUTIES =>
				byteCounter := 72;
				d_state := s_dataByte;
			when CODE_SET_PLL =>
				byteCounter := 18;
				d_state := s_dataByte;
			when CODE_INQUIRE_MASTER =>
				byteCounter := 0;
				d_state := s_requestCrc;
			when CODE_SYNC_DIVIDERS =>
				byteCounter := 0;
				d_state := s_requestCrc;
			when others =>
				byteCounter := 0;
				d_state := s_requestCrc;
		end case;
		dataLen := byteCounter;
		dataBuffer := dataBuffer((BUF_LEN - 8) downto 0) & codeByte;

	when s_dataByte =>
		if lastValid = '0' and thisValid = '1' then
				--gotten new byte!
				dataBuffer := dataBuffer((BUF_LEN - 8) downto 0) & incomingByte;
				byteCounter := byteCounter - 1;
		end if;
		if byteCounter = 0 then
				d_state := s_requestCrc;
		end if;
		
	when s_requestCrc =>
			byteCounter := CRC_LEN/8;
			crcRequest <= '1'; 
			dataBufferSig <= dataBuffer;
			crcDataLen <= (dataLen + 1) * 8; --plus one because of the opening code byte
			d_state := s_crcByte;
	
	when s_crcByte =>
		if lastValid = '0' and thisValid = '1' then
			--gotten new byte!
			byteCounter := byteCounter - 1;
			crcGotten((8*(byteCounter+1) - 1) downto 8*byteCounter) := incomingByte;
			if byteCounter = 0 then
				d_state := s_crcWaitR;
			end if;
		end if;
	
	when s_crcWaitR =>
		if crcReady = '1' then
			crcCalced := crcSig;
			d_state := s_evaluate;
		end if;
		
	when s_evaluate =>
		crcIsCorrect := '0';
		if crcCalced = crcGotten then
			crcIsCorrect := '1';
		end if;
		
		if crcIsCorrect = '1' then
			reply(7 downto 4) := REPLY_CRC_OK;
		else
			reply(7 downto 4) := REPLY_CRC_FAIL;
		end if;
		
		case codeByte is
			when CODE_SET_PHASES =>
				d_state := s_doPhases;
			when CODE_SET_DUTIES =>
				d_state := s_doDuties;
			when CODE_INQUIRE_MASTER =>
				d_state := s_doInquire;
			when CODE_SYNC_DIVIDERS =>
				d_state := s_prepSync;
			when others =>
				d_state := s_unknownCode;
		end case;
		
	when s_doPhases =>
		
		if crcIsCorrect = '1' then
			chan_phases <= dataBuffer(575 downto 0);
		end if;
		reply(3 downto 0) := REPLY_SET_PHASES;
		d_state := s_transmitReply;
	
	when s_doDuties =>
		if crcIsCorrect = '1' then
			chan_duties <= dataBuffer(575 downto 0);
		end if;
		reply(3 downto 0) := REPLY_SET_DUTIES;
		d_state := s_transmitReply;
		
	when s_doInquire =>
		
		if master_in = '1' then
			reply(3 downto 0) := REPLY_I_AM_MASTER;
		else
			reply(3 downto 0) := REPLY_I_AM_SLAVE;
		end if;
		d_state := s_transmitReply;
		
	when s_prepSync =>
		if master_in = '0' then
			reply(3 downto 0) := REPLY_SYNC_NOT_MASTER;
			d_state := s_transmitReply;
		else
			reply(3 downto 0) := REPLY_SYNC_OK;
			syncCounter := 0;
			d_state := s_performSync;
		end if;
		
	when s_performSync =>
		reset <= '1';
		master_clock_enable <= '0';
		
		if syncCounter > resetCount then
			reset <= '0';
		end if;
		
		if syncCounter > enableCount then
			master_clock_enable <= '1';
			d_state := s_transmitReply;
		end if;
			
		syncCounter := syncCounter + 1;
	
	when s_transmitReply =>
		 
		uart_send_byte <= reply;
		if uart_ready = '1' then
			uart_send_start <= '1';
			d_state := s_ready;
		end if;
		
	when s_unknownCode =>
		reply(3 downto 0) := REPLY_UNKNOWN_CODE;
		d_state := s_transmitReply;
	
		
	
	
	end case;
  
  

		
  end if;
 
  end process decode;
  
  
  
  
 calculateCrc : process(CLK) is
 
  variable dataBuffer : std_logic_vector(BUF_LEN + CRC_LEN  downto 0) := (others => '0');
  variable polyBuffer : std_logic_vector(BUF_LEN + CRC_LEN  downto 0) := (others => '0');
  constant ZEROS : std_logic_vector(dataBuffer'range) := (others => '0');
  variable dataLen : integer range 0 to BUF_LEN := 0;
  variable leadingBit : integer range 0 to BUF_LEN + CRC_LEN := 0; 
  
  variable c_state : cStates_t := s_ready;
  variable alreadyCalced : std_logic := '0';
 
  
  begin
  
  if rising_edge(CLK) then
  
	case c_state is
	
	when s_ready =>
		crcReady <= alreadyCalced;
		if crcRequest = '1' then
				dataLen := crcDataLen + 8;
				dataBuffer(BUF_LEN + CRC_LEN downto CRC_LEN) := dataBufferSig(BUF_LEN downto 0);
				--dataBuffer(CRC_LEN - 1 downto 0) := (others => '0');
				polyBuffer(dataLen + CRC_LEN downto dataLen) := CRC_POLY(CRC_LEN downto 0);
				--polyBuffer(dataLen - CRC_LEN downto 0) := (others => '0');
				leadingBit := dataLen + CRC_LEN;
				alreadyCalced := '0';
				crcReady <= '0';
				c_state := s_shift;
		end if;
		
	when s_calculating =>
		crcReady <= '0';
		dataBuffer := dataBuffer xor polyBuffer;
		if dataBuffer(BUF_LEN + CRC_LEN downto CRC_LEN) = ZEROS(BUF_LEN + CRC_LEN downto CRC_LEN) then
			c_state := s_complete;
		else
			polyBuffer := "0" & polyBuffer(BUF_LEN + CRC_LEN  downto 1);
			leadingBit := leadingBit - 1;
			if dataBuffer(leadingBit) = '0' then
			   c_state := s_shift;
			end if;
			if leadingBit = 0 then
				c_state := s_complete;
			end if;
		end if;
		
	when s_shift =>
		crcReady <= '0';
		if dataBuffer(leadingBit) = '1' then
			c_state := s_calculating;
		else
			polyBuffer := "0" & polyBuffer(BUF_LEN + CRC_LEN  downto 1);
			leadingBit := leadingBit - 1;
			if leadingBit = 0 then
				c_state := s_complete;
			end if;
		end if;

	when s_complete =>
		alreadyCalced := '1';
		crcReady <= '0';
		crcSig <= dataBuffer(CRC_LEN-1 downto 0);
		dataBuffer := (others => '0');
		polyBuffer := (others => '0');
		c_state := s_ready;
	end case;
  
  
	
  end if;
 
  end process calculateCrc;
  
  
  
  
  
  
  
  
  
end arch1;



