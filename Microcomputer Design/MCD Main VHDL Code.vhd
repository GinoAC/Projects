--Gino Chacon
--Microcomputer Design Spring 2015
--Main CPLD Code
--THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED.
--Completed 4-12-2015
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity maintwo is

Port(

		----------------
		--| CPU PINS |--
		----------------
		ADDRESS : 	IN 	STD_LOGIC_VECTOR(7 downto 0);
		AS 		: 	IN 	STD_LOGIC;
		CPU_RW	:	IN 	STD_LOGIC;
		UDS		:	IN 	STD_LOGIC;
		LDS		:	IN 	STD_LOGIC;
		FC 		:	IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
		E		:	IN	STD_LOGIC;
		VMA		:	IN	STD_LOGIC;
		BG		:	IN	STD_LOGIC;
		
		HLT		:	OUT	STD_LOGIC := '1';
		RESET	:	OUT	STD_LOGIC := '1';
		
		DTACK	:	OUT STD_LOGIC;
		
		BGACK	:	OUT STD_LOGIC := '1';
		BR		:	OUT	STD_LOGIC := '1';
		VPA		:	OUT	STD_LOGIC := '1';
		IPL		:	OUT	STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";
		BERR	:	OUT	STD_LOGIC := '1';
		
		
		----------------------------------
		--|FOR RAM AND ROM:				 |
		--|ROM1 and RAM1 are upper bytes |
		--|RAM1 and RAM2 are lower bytes |
		--|bit order:"2,1,0"			 |		
		--|<2> = WE*					 |
		--|<1> = OE*					 |
		--|<0> = CE*					 |
		----------------------------------
		ROM1	:	OUT	STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";
		ROM2	: 	OUT STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";
		RAM1	:	OUT	STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";
		RAM2	:	OUT STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";
	
		----------------------------------
		--|FOR THE DUART				 |
		--|DUART_CTRL bit order: "1,0"	 |
		--|<1> = CS*					 |
		--|<0> = RW*					 |
		----------------------------------
		--FOR DUART_CTRL: <1> = CS, <0> = RW 
		DUART_INTR  :	IN	STD_LOGIC;		
		DUART_CTRL	:	OUT	STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";
		
		DUART_OP	:	IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
		DUART_IP	:	OUT	STD_LOGIC_VECTOR(5 DOWNTO 0) := "111111";
		DUART_RESET	:	OUT	STD_LOGIC := '1';
		DUART_IACK	:	OUT	STD_LOGIC := '1';
		
		--CPLD PIN OUTS AND CLOCK
		CLK			:	IN 	STD_LOGIC;
		reset_button 	:	IN STD_LOGIC;
		DBUG		:OUT	STD_LOGIC_VECTOR(10 DOWNTO 0)
	);
	
end maintwo;

architecture Behavioral of maintwo is
													---====================---
													--|ARCHITECTURE SIGNALS|--
													---====================---
	
	signal startup_flag	: STD_LOGIC := '1'; 			--Indicates the system has just powered on
	
	signal clockCount1	: integer range 0 to 5000000:=0	;	--Counters for clock dividing
	
	signal DTACK_SIG		: STD_LOGIC;
	signal timer 			: integer range 0 to 5:=5;	--Timer for DTACK generation
	signal AS_Tempsig		: STD_LOGIC := '1';
	signal buttonPush		: STD_LOGIC := '0';
	
begin	
		
		ROM1<= 	"100" when AS = '0' and UDS = '0' and ADDRESS(1) = '0' and ADDRESS(0) = '0' else
			    "111";
		ROM2<= 	"100" when AS = '0' and LDS = '0' and ADDRESS(1) = '0' and ADDRESS(0) = '0' else
			    "111";
		RAM1<= 	"100" when AS = '0' and CPU_RW = '1' and UDS = '0' and ADDRESS(1) = '0' and ADDRESS(0) = '1' else --Read
			 	"010" when AS = '0' and CPU_RW = '0' and UDS = '0' and ADDRESS(1) = '0' and ADDRESS(0) = '1' else --Write
			    "111";
		RAM2<= 	"100" when AS = '0' and CPU_RW = '1' and LDS = '0' and ADDRESS(1) = '0' and ADDRESS(0) = '1' else --Read
			 	"010" when AS = '0' and CPU_RW = '0' and LDS = '0' and ADDRESS(1) = '0' and ADDRESS(0) = '1' else --Write
			    "111";
		DUART_CTRL <= "01" when AS = '0' and CPU_RW = '1' and ADDRESS(1) = '1' and ADDRESS(0) = '0' else --Read
				"00" when AS = '0' and CPU_RW = '0' and ADDRESS(1) = '1' and ADDRESS(0) = '0' else --write
				"11";
		
	---====================---
	--|		Glue Logic	   |--
	---====================---
		BGACK	<= '1';
		BR		<= '1';
		VPA	<= '1';
		IPL 	<= "111";
		BERR 	<= '1';
		DUART_IP		<= "111111";
		
		DUART_IACK	<= '1';
		
		
		
		
	---====================---
	--|	  Power-on Reset   |--
	---====================---		
		system_reset: process( CLK ) begin
			if rising_edge( CLK ) then
				if ( startup_flag = '1') then
					buttonPush <= '1';						--If its the first time startup or the reset button has been pushed
					HLT 	<= '0'; 							--assert halt and reset
					RESET <= '0';							--then count to 1000 a 1000 times which is roughly 100ms at a 10Mhz clock input
					DUART_RESET	<= '0';
					if( clockCount1 = 5000000 ) then		--If clock count 1 is at its max, 
							clockCount1 <= 0;
							DUART_RESET	<= '1';
							HLT <= '1';						--set HLT and RESET high again
							RESET <= '1';					--
							startup_flag <= '0';			--set startup_flag to 0 so it knows that it is no longer at startup.
							buttonPush <= '0';
					else
						clockCount1 <= clockCount1 + 1;				--Incrementing clock count 1
					end if;
				end if;
			end if;
		end process;
	
	
	---====================---
	--|		Dtack	 	   |--
	---====================---
	
		DTACK_GENERATION: process( CLK ) begin
		
			if(rising_edge(CLK)) then
				if(ADDRESS(1) = '0') THEN
					if ( AS = '0' and AS /= AS_Tempsig ) then	--If AS is asserted and it was not before then
						timer <= 5;								--set starting timer and
						DTACK <= '1';							--do not generate DTACK.
						DTACK_SIG <= '1';
					end if;
					
					AS_Tempsig <= AS;							--Set the current state of the AS as the last state
					
					if ( timer /= 0 ) then						--If timer has not reached its goal
						timer <= timer - 1;						--decrement it.
					elsif ( timer = 0 and AS = '0' ) then		--If timer end has been reached and address strobe is asserted then
						DTACK <= '0';							--send a DTACK signal.
						DTACK_SIG <= '0';
					elsif (AS = '1' and DTACK_SIG = '0' ) then	--If UDS,LDS, and AS are not asserted but DTACK is then
						DTACK <= '1';							--unassert the DTACK
						DTACK_SIG <= '1';
					end if;
					
					if(AS = '1') then
						DTACK <= '1';
					end if;
				ELSE
					DTACK <= 'Z';
				end if;
				end if;
			
		end process;		
		
end Behavioral;

