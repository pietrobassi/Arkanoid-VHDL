--Authors: Pietro Bassi, Marco Torsello

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity arkanoid_keyboard is
port 
	(
		KEYBOARD_CLOCK 	: in  STD_LOGIC;
		KEYBOARD_DATA 		: in  STD_LOGIC;
		KEY_LEFT 			: out std_logic;
		KEY_RIGHT 			: out std_logic;
		KEY_PAUSE 			: out std_logic;
		KEY_START 			: out std_logic
	);
end arkanoid_keyboard;

architecture RTL of arkanoid_keyboard is

signal codeReady 			: STD_LOGIC := '0';
signal code 				: STD_LOGIC_VECTOR(7 downto 0);

begin

	KeyboardProcess : process(KEYBOARD_CLOCK)
	
	constant FRAMELENGHT 				: integer := 12;
	variable keyboardCounter 			: integer range 0 to FRAMELENGHT := 0;
	variable paritykeyboardCounter 	: integer range 0 to FRAMELENGHT := 0;
	variable parity 						: integer range 0 to 1 := 0;
	begin
		--PS/2 protocol
		if falling_edge(KEYBOARD_CLOCK) then
			if (keyboardCounter = 0 and KEYBOARD_DATA = '0') then -- start, first bit always 0
				codeReady <= '0';
				paritykeyboardCounter :=0;
				parity:=0;
				keyboardCounter := keyboardCounter + 1;	
			elsif (keyboardCounter > 0 and keyboardCounter < FRAMELENGHT - 3)  then 
				code <= KEYBOARD_DATA & code(7 downto 1);
				if (KEYBOARD_DATA = '1') then --count number of 1s
					paritykeyboardCounter := paritykeyboardCounter + 1;
				end if;
				keyboardCounter := keyboardCounter + 1;
			elsif (keyboardCounter = FRAMELENGHT - 3) then --check parity
				if(paritykeyboardCounter mod 2 = 0 and KEYBOARD_DATA = '1') then --even 1s
					parity := 1;
				elsif(paritykeyboardCounter mod 2 = 1 and KEYBOARD_DATA = '0' ) then --odd 1s
					parity := 1;
				else
					parity := 0;
				end if;
				keyboardCounter := keyboardCounter + 1;
			elsif (keyboardCounter = FRAMELENGHT - 2) then -- end, last bit always 1
				if (parity = 1 and KEYBOARD_DATA ='1') then 
					codeReady <= '1';
				end if;
				keyboardCounter := 0;			
			end if;
		end if;		
	end process KeyboardProcess;
	
	
	SendProcess : process(codeReady, code)
		
	--thanks to this variable it is possibile to determine whether a button has been pressed or released
	variable afterBreakCode 			: std_logic:='0';
	
	begin
		if codeReady'event and codeReady = '1' then
				case code is
				--breakcode
				when X"F0" =>
					afterBreakCode:='1';
				--LEFT, 'Y' key
				when X"35" =>				
					if(afterBreakCode='1') then
						KEY_LEFT<= '0';
						afterBreakCode:='0';
					else
						KEY_LEFT<= '1';
						KEY_RIGHT<= '0';
					end if;	
				--RIGHT, 'I' key	
				when X"43" =>
					if(afterBreakCode='1') then
						KEY_RIGHT<= '0';
						afterBreakCode:='0';
					else
						KEY_RIGHT<= '1';
						KEY_LEFT<= '0';
					end if;	
				--PAUSE, 'P' key
				when X"4D" =>
					if(afterBreakCode='1') then
						KEY_PAUSE<= '0';
						afterBreakCode:='0';
					else
						KEY_PAUSE<= '1';
						--this prevents the player from "cheating" pressing simultaneosuly PAUSE and START buttons, "slowing" game time
						KEY_START<= '0';
					end if;	
				--START, 'SPACE' key
				when X"29" =>
					if(afterBreakCode='1') then
						KEY_START<= '0';
						afterBreakCode:='0';
					else
						KEY_START<= '1';
						KEY_PAUSE<= '0';
					end if;	
				when others => 
					KEY_START<= '0';
				end case;

		end if;
	end process SendProcess;
	
	
end architecture;
