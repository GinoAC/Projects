
;Set stack location and the main program's location
START	    ORG		$000000
		    DC.L    SUPERSTACK
            DC.L    MAIN

*           JSR GET_CHAR
MAIN		ORG	$000100
            IF.B	SIM <NE> #00 THEN.L ;when simulating, turn off keyboard echo
        	MOVE.B	#$00,D1
        	MOVE.B	#12,D0
        	TRAP	#15
        	ENDI
	  		JSR INIT_DUART		;INITIALIZE DUART
		    JSR	START_HELP		;DISPLAY MAIN MENU

;--------------------------MAIN PART--------------------------;

MAIN1		JSR NEWLINE
			LEA	MAINMESS,A1
			JSR OUTS
			MOVE.L #$00,D3
MAIN2		JSR INPUT_CHAR		;TAKE INPUT CHARACTER
            MOVE.B D1,D0		;MOVE CHARACTER TO D0
 			JSR	PUT_CHAR		;OUTPUT CHARACTER
			CMP.B #$0D,D1
			BEQ	CMDPARSE
			ADD.B D1,D3
			CMP.B #$9F,D3
			BHI	INVALID
			JMP MAIN2
			
;CHECKS TO SEE IF A COMMAND HAS BEEN ENTERED THEN JUMPS TO THAT COMMAND
CMDPARSE	JSR	NEWLINE
			CMP.B #$48,D3		;HELP MENU
			BEQ	SHOWHELP
			CMP.B #$91,D3		;MD
			BEQ	MD_JMP			
			CMP.B   #$9A,D3		;MM
			BEQ	MM_JMP			
			CMP.B	#$9F,D3		;RM
			BEQ	RM_JMP			
			CMP.B   #$96,D3		;RD
			BEQ	RD_JMP
			CMP.B	#$53,D3		;S
			BEQ	S_JMP
            CMP.B	#$97,D3		;SD
			BEQ	SD_JMP			
			BRA	INVALID
			
SHOWHELP	JSR	START_HELP
			MOVE.L	#$00,D3
			JMP	MAIN1
			
			;DISPLAYS INVALID COMMAND MESSAGE
INVALID		JSR	INV
			MOVE.L	#$00,D3
			JMP MAIN1			
			
;JUMPS TO THE MEMORY DUMP SUBROUTINE
MD_JMP		MOVE.L	A1,-(A7)
			LEA MEMDUMP,A1
			JSR OUTS
			MOVE.L (A7)+,A1
			JSR MD_MAIN
			MOVE.L	#$00,D3
			JMP MAIN1
			
;JUMPS TO THE MEMORY MODIFY SUBROUTINE			
MM_JMP		MOVE.L	A1,-(A7)
			LEA MEMMOD,A1
			JSR OUTS
			MOVE.L (A7)+,A1
			JSR MM_MAIN
			MOVE.L	#$00,D3
			JMP MAIN1
			
;JUMPS TO THE REGISTER MODIFY SUBROUTINE						
RM_JMP		MOVE.L	A1,-(A7)
			LEA REGMOD,A1
			JSR OUTS
			MOVE.L (A7)+,A1
			JSR RM_MAIN
			MOVE.L	#$00,D3
			JMP MAIN1

;JUMPS TO THE REGISTER DUMP SUBROUTINE									
RD_JMP		MOVE.L	A1,-(A7)
			LEA REGDUMP,A1
			JSR OUTS
			MOVE.L (A7)+,A1
			JSR RD_MAIN
			MOVE.L	#$00,D3
			JMP MAIN1

;SRECORD JUMP 			
S_JMP		MOVE.L	A1,-(A7)
			LEA SREC,A1
			JSR OUTS
			MOVE.L (A7)+,A1
			JSR S_MAIN
			MOVE.L	#$00,D3
			JMP MAIN1	
			
;RUNS THE SRECORD			
SD_JMP		MOVE.L	A1,-(A7)
			LEA SREC,A1
			JSR OUTS
			MOVE.L (A7)+,A1
			JSR (A3)
			MOVE.L	#$00,D3
			JMP MAIN1			

;DISPLAYS INVALID INPUT 			
INV			MOVE.L	A1,-(A7)
			JSR	NEWLINE
			LEA INVALIDSTATEMENT,A1
			JSR OUTS
			MOVE.L (A7)+,A1
			RTS
			
;----------------------- MEMORY DUMPING START ----------------------------------;
MD_MAIN 	MOVE.L	A1,-(A7)
			MOVE.L	A0,-(A7)
            MOVE.L #$00,D0
            MOVE.L #$00,D1
            MOVE.L #$00,D2
			
			MOVE.L #$00,D7
MD_GETLOC	CMP.B #$05,D7     ;CHECK IF COUNTER REACHED 8
            BEQ MD_DUMP      ;IF SO, END DISPLAY FUNCTION
            JSR INPUT_CHAR    ;GET VALUE
            MOVE.B D1,D0	;MOVE CHARACTER TO D0
            JSR PUT_CHAR    ;OUTPUT IT
            CMP.B #$30,D1     ;CHECK IF VALID NUMBER
            BHS MD_NEXT3	;IF GREATER THAN 0
            JSR INV		
            BRA MD_FIN		
MD_NEXT3    CMP.B #$39,D1		;IF GREATER THAN 9
            BHI MD_NEXT4
            SUB #$30,D1
            BRA MD_NEXT7
MD_NEXT4    CMP.B #$41,D1		;CHECK IF ITS HEX A<
            BHS MD_NEXT5
            JSR INV
            BRA MD_FIN
MD_NEXT5    CMP.B #$46,D1		;CHECK IF <F
            BLS MD_NEXT6
            JSR INV
            BRA MD_FIN
MD_NEXT6    SUB #$41,D1		;IF ASCII SUBTRACT 41
            ADD #$0A,D1
MD_NEXT7    ROL.L #4,D2
            OR.L  D1,D2
            ADD #$01,D7
            BRA MD_GETLOC
					
MD_DUMP		MOVE.L	D2,A0
			MOVE.L  #$20,D0
			JSR	PUT_CHAR
MD_DUMP1    MOVE.B	(A0)+,D2 ;PUT DATA IN D2
			;SECOND NIBBLE OF DATA LOC
   		    MOVE.B	D2,D3	;PUT D2 TO D3
   		    ROR	#4,D3
			AND	#$0F,D3		;GET THE FIRST NIBBLE
			CMP.B	#$09,D3		;CHECK IF ITS ABOVE 9
			BHI	MD_HEX2		;IF IT IS, CONVERT TO HEX ASCII
			ADD	#$30,D3		;OTHERWISE CONVERT TO DIGIT ASCII
			BRA	MD_OUT2		
MD_HEX2		ADD	#$37,D3
MD_OUT2		MOVE.B	D3,D0	;OUTPUT SECOND NIBBLE
			JSR	PUT_CHAR	;OUTPUT DATA AT LOC
			;SPACE
		    MOVE.B	D2,D3	;PUT D2 TO D3
			AND	#$0F,D3		;GET THE FIRST NIBBLE
			CMP.B	#$09,D3		;CHECK IF ITS ABOVE 9
			BHI	MD_HEX1		;IF IT IS, CONVERT TO HEX ASCII
			ADD	#$30,D3		;OTHERWISE CONVERT TO DIGIT ASCII
			BRA	MD_OUT1		
MD_HEX1		ADD	#$37,D3
MD_OUT1		MOVE.B	D3,D0	;OUTPUT FIRST NIBBLE
			JSR	PUT_CHAR	;OUTPUT DATA AT LOC
			MOVE.L  #$20,D0
			JSR	PUT_CHAR
			
			JSR	INPUT_CHAR	;IF THEY HIT Q, END LOOP OTHERWISE ANY KEY CONTINUES IT
			CMP.B	#$51,D1
			BEQ	MD_FIN
			BRA	MD_DUMP1			
MD_FIN		MOVE.L	(A7)+,A0
			MOVE.L	(A7)+,A1
			RTS
;----------------------- MEMORY DUMPING END ----------------------------------;
;----------------------- MEMORY MODIFYING START ----------------------------------;
MM_MAIN     MOVE.L  A0,-(A7)
            MOVE.L  A1,-(A7)
            MOVE.L #$00,D0
            MOVE.L #$00,D1
            MOVE.L #$00,D2
			MOVE.L #$00,A0
			MOVE.L #$00,D7
MM_GETLOC	CMP.B #$05,D7     ;CHECK IF COUNTER REACHED 5
            BEQ MM_MOD        ;IF SO, END DISPLAY FUNCTION
            JSR INPUT_CHAR    ;GET VALUE
            MOVE.B D1,D0	;MOVE CHARACTER TO D0
            JSR PUT_CHAR    ;OUTPUT IT
            CMP.B #$30,D1     ;CHECK IF VALID NUMBER
            BHS MM_NEXT3	;IF GREATER THAN 0
            JSR INV		
            BRA MM_FIN		
MM_NEXT3    CMP.B #$39,D1		;IF GREATER THAN 9
            BHI MM_NEXT4
            SUB #$30,D1
            BRA MM_NEXT7
MM_NEXT4    CMP.B #$41,D1		;CHECK IF ITS HEX A<
            BHS MM_NEXT5
            JSR INV
            BRA MM_FIN
MM_NEXT5    CMP.B #$46,D1		;CHECK IF <F
            BLS MM_NEXT6
            JSR INV
            BRA MM_FIN
MM_NEXT6    SUB #$41,D1		;IF ASCII SUBTRACT 41
            ADD #$0A,D1
MM_NEXT7    ROL.L #4,D2
            OR.L  D1,D2
            ADD #$01,D7
            BRA MM_GETLOC
MM_MOD      JSR NEWLINE
            MOVE.L D2,A0
            MOVE.L #$00,D2
            MOVE.L #$00,D7

MM_MOD1	    CMP.B #$02,D7     ;CHECK IF COUNTER REACHED 2
            BEQ MM_MOD2      ;IF SO, END DISPLAY FUNCTION
            JSR INPUT_CHAR    ;GET VALUE
            MOVE.B D1,D0	;MOVE CHARACTER TO D0
            JSR PUT_CHAR    ;OUTPUT IT
            CMP.B #$30,D1     ;CHECK IF VALID NUMBER
            BHS MM_NEXT8	;IF GREATER THAN 0
            JSR INV		
            BRA MM_FIN		
MM_NEXT8    CMP.B #$39,D1		;IF GREATER THAN 9
            BHI MM_NEXT9
            SUB #$30,D1
            BRA MM_NEXT12
MM_NEXT9    CMP.B #$41,D1		;CHECK IF ITS HEX A<
            BHS MM_NEXT10
            JSR INV
            BRA MM_FIN
MM_NEXT10   CMP.B #$46,D1		;CHECK IF <F
            BLS MM_NEXT11
            JSR INV
            BRA MM_FIN
MM_NEXT11   SUB #$41,D1		;IF ASCII SUBTRACT 41
            ADD #$0A,D1
MM_NEXT12   ROL.L #4,D2
            OR.L  D1,D2
            ADD #$01,D7
            BRA MM_MOD1 
MM_MOD2     MOVE.B D2,(A0)
            JSR NEWLINE   
MM_FIN		MOVE.L	(A7)+,A0
			MOVE.L	(A7)+,A1
			RTS 			
;----------------------- MEMORY MODIFYING START ----------------------------------;
			
			
			
			
;----------------------- REGISTER MODIFYING START ----------------------------------;
;FOR REGISTER MODIFYING 
;UNABLE TO MODIFY D0-D3,D7,A0-A3,AND A7
RM_MAIN     MOVE.L A1,-(A7)
            MOVE.L #$00,D0
            MOVE.L #$00,D1
            MOVE.L #$00,D2
            LEA RMWARN,A1
            JSR OUTS
RM_DORA     JSR INPUT_CHAR		;TAKE INPUT CHARACTER
            MOVE.B D1,D0		;MOVE CHARACTER TO D0
 			JSR	PUT_CHAR		;OUTPUT CHARACTER
 			CMP.B #$44,D1         ;SEE IF ITS A D, IF SO JUMP TO DATA DUMP
 			BEQ RM_VALID         
 			CMP.B #$41,D1         ;SEE IF ITS AN A, IF SO JUMP TO ADDRESS DUMP
 			BEQ RM_VALID
 			JSR INV             ;OF NONE OF THESE, INVALID OPTION
 			BRA RM_FIN
RM_VALID    SUB #$37,D1         ;CONVERT A OR D FROM ASCII TO HEX
            MOVE.B D1,D3
            ROL.L #4,D3         ;MOVE IT OVER A NIBBLE
RM_REGNUM   JSR INPUT_CHAR
            MOVE.B D1,D0		;MOVE CHARACTER TO D0
 			JSR	PUT_CHAR		;OUTPUT CHARACTER
 		    CMP.B #$34,D1         ;CHECK IF INPUT NUMBER IS VALID
 		    BHS RM_NEXT1
            JSR INV             ;IF NOT THEN INVALID
 		    BRA RM_FIN
RM_NEXT1    CMP.B #$36,D1         ;CHECK IF INPUT NUMBER IS VALID
   		    BLS RM_NEXT2    
            JSR INV             ;IF NOT THEN INVALID
  		    BRA RM_FIN
RM_NEXT2    SUB #$30,D1         ;CONVERT IT INTO HEX
            OR.B D1,D3          ;OR IT WITH D3 TO PUT THEM IN THE SAME REGISTER            
            MOVE.L #$00,D2
            MOVE.L #$00,D7
            JSR NEWLINE
RM_MODIFY1	CMP.B #$08,D7     ;CHECK IF COUNTER REACHED 8
            BEQ RM_MODIFY2      ;IF SO, END DISPLAY FUNCTION
            JSR INPUT_CHAR    ;GET VALUE
            MOVE.B D1,D0	;MOVE CHARACTER TO D0
            JSR PUT_CHAR    ;OUTPUT IT
            CMP.B #$30,D1     ;CHECK IF VALID NUMBER
            BHS RM_NEXT3	;IF GREATER THAN 0
            JSR INV		
            BRA RM_FIN		
RM_NEXT3    CMP.B #$39,D1		;IF GREATER THAN 9
            BHI RM_NEXT4
            SUB #$30,D1
            BRA RM_NEXT7
RM_NEXT4    CMP.B #$41,D1		;CHECK IF ITS HEX A<
            BHS RM_NEXT5
            JSR INV
            BRA RM_FIN
RM_NEXT5    CMP.B #$46,D1		;CHECK IF <F
            BLS RM_NEXT6
            JSR INV
            BRA RM_FIN
RM_NEXT6    SUB #$41,D1		;IF ASCII SUBTRACT 41
            ADD #$0A,D1
RM_NEXT7    ROL.L #4,D2
            OR.L  D1,D2
            ADD #$01,D7
            BRA RM_MODIFY1                  
;PUT IN	
RM_MODIFY2  CMP.B #$D4,D3
            BNE RDL1
            MOVE.L D2,D4
            BRA RM_FIN
 
RDL1        CMP.B #$D5,D3
            BNE RDL2
            MOVE.L D2,D5
            BRA RM_FIN            
 
RDL2        CMP.B #$D6,D3
            BNE RDL3
            MOVE.L D2,D6
            BRA RM_FIN

RDL3        CMP.B #$A4,D3
            BNE RDL4
            MOVE.L D2,A4
            BRA RM_FIN

RDL4        CMP.B #$A5,D3
            BNE RDL5
            MOVE.L D2,A5
            BRA RM_FIN

RDL5        CMP.B #$A6,D3
            MOVE.L D2,A6
            BRA RM_FIN 
 
RM_FIN  	MOVE.L (A7)+,A1
			RTS

			
;----------------------- REGISTER MODIFYING END ----------------------------------;



			
;-------------------------------------REGISTER DUMP START--------------------------------------------------;

RD_MAIN		MOVE.L	A1,-(A7)
			JSR INPUT_CHAR		;TAKE INPUT CHARACTER
            MOVE.B D1,D0		    ;MOVE CHARACTER TO D0
 			JSR	PUT_CHAR		    ;OUTPUT CHARACTER
 			CMP.B #$44,D1          ;SEE IF ITS A D, IF SO JUMP TO DATA DUMP
 			BEQ RD_DATA         
 			CMP.B #$41,D1          ;SEE IF ITS AN A, IF SO JUMP TO ADDRESS DUMP
 			BEQ RD_ADD
 			JSR INV              ;OF NONE OF THESE, INVALID OPTION
 			BRA RD_FIN

RD_DATA     JSR INPUT_CHAR		;TAKE INPUT CHARACTER
            MOVE.B D1,D0		;MOVE CHARACTER TO D0
 			JSR	PUT_CHAR		;OUTPUT CHARACTER
 		    CMP.B #$30,D1         ;CHECK IF INPUT NUMBER IS VALID
 		    BHS RD_NEXT1
            JSR INV             ;IF NOT THEN INVALID
 		    BRA RD_FIN
RD_NEXT1    CMP.B #$37,D1         ;CHECK IF INPUT NUMBER IS VALID
   		    BLS RD_NEXT2    
            JSR INV             ;IF NOT THEN INVALID
 		    BRA RD_FIN
RD_NEXT2    MOVE.L  D1,D3
            SUB #$30,D3

            CMP.B #$0,D3  ;SHOWS DATA REG 0
            BNE RDATA1
            MOVE.L D0,D2
            BRA RD_DISP

RDATA1      CMP.B #$1,D3  ;SHOWS DATA REG 1
            BNE RDATA2
            MOVE.L D1,D2
            BRA RD_DISP
            
RDATA2      CMP.B #$2,D3  ;SHOWS DATA REG 2
            BNE RDATA3
            MOVE.L D2,D2
            BRA RD_DISP

RDATA3      CMP.B #$3,D3  ;SHOWS DATA REG 3
            BNE RDATA4
            MOVE.L D3,D2
            BRA RD_DISP            
            
RDATA4      CMP.B #$4,D3  ;SHOWS DATA REG 4
            BNE RDATA5
            MOVE.L D4,D2
            BRA RD_DISP            
            
RDATA5      CMP.B #$5,D3  ;SHOWS DATA REG 5
            BNE RDATA6
            MOVE.L D5,D2
            BRA RD_DISP            
            
RDATA6      CMP.B #$6,D3  ;SHOWS DATA REG 6
            BNE RDATA7
            MOVE.L D6,D2
            BRA RD_DISP            
            
RDATA7      CMP.B #$7,D3  ;SHOWS DATA REG 7
            MOVE.L D7,D2
            BRA RD_DISP

RD_ADD 		JSR INPUT_CHAR		;TAKE INPUT CHARACTER
            MOVE.B D1,D0		;MOVE CHARACTER TO D0
 			JSR	PUT_CHAR		;OUTPUT CHARACTER
 		    CMP.B #$30,D1
 		    BHS RD_NEXT3
            JSR INV
 		    BRA RD_FIN
RD_NEXT3    CMP.B #$37,D1
   		    BLS RD_NEXT4
            JSR INV
 	        BRA RD_FIN
RD_NEXT4    MOVE.L  D1,D3
            SUB #$30,D3

            CMP.B #$0,D3  ;SHOWS ADD REG 0
            BNE RDADD1
            MOVE.L A0,D2
            BRA RD_DISP

RDADD1      CMP.B #$1,D3  ;SHOWS ADD REG 1
            BNE RDADD2
            MOVE.L A1,D2
            BRA RD_DISP
            
RDADD2      CMP.B #$2,D3  ;SHOWS ADDTA REG 2
            BNE RDADD3
            MOVE.L A2,D2 
            BRA RD_DISP

RDADD3      CMP.B #$3,D3  ;SHOWS ADD REG 3
            BNE RDADD4
            MOVE.L A3,D2
            BRA RD_DISP            
            
RDADD4      CMP.B #$4,D3  ;SHOWS ADD REG 4
            BNE RDADD5
            MOVE.L A4,D2
            BRA RD_DISP            
            
RDADD5      CMP.B #$5,D3  ;SHOWS ADD REG 5
            BNE RDADD6
            MOVE.L A5,D2
            BRA RD_DISP            
            
RDADD6      CMP.B #$6,D3  ;SHOWS ADD REG 6
            BNE RDADD7
            MOVE.L A6,D2
            BRA RD_DISP            
            
RDADD7      CMP.B #$7,D3  ;SHOWS ADD REG 7
            MOVE.L A7,D2
            BRA RD_DISP
                       

RD_DISP     MOVE.L #$00,D7   ;INITIALIZE COUNTER IN D7
            JSR NEWLINE
RD_DISP1    CMP.B #$08,D7     ;CHECK IF COUNTER REACHED 8
            BEQ RD_FIN      ;IF SO, END DISPLAY FUNCTION
            ROL.L #4,D2
            MOVE.B D2,D0    ;MOVE BYTE OF D2 INTO D0
            AND #$0F,D0     ;SELECT LOWER HALF OF BYTE
            CMP.B #$0A,D0     ;CHECK IF ITS ABOVE 9
            BHS RLETTER     ;IF IT IS BRANCH
            ADD #$30,D0     ;OTHERWISE ADD #$30 TO IT AND DISPLAY            
            BRA RD_DISP2    
RLETTER     SUB #$0A,D0     ;IF IT WAS ABOUT 9, SUBTRACT A FROM IT AND ADD 41            
            ADD #$41,D0
RD_DISP2    JSR PUT_CHAR        
            ADD #$01,D7     ;INCREMENT COUNTER
            BRA RD_DISP1    ;CONTINUE LOOP
RD_FIN  	MOVE.L (A7)+,A1
			RTS

;------------------------------------- REGISTER DUMP END --------------------------------------------------;
;-------------------------------------  SRECORD STARTS   --------------------------------------------------;
S_MAIN      MOVE.L	A1,-(A7)
            LEA SRSTRT,A1
            JSR OUTS
            JSR NEWLINE
S_GET       MOVE.L  #$00,D0
            JSR INPUT_CHAR  ;GET S
            JSR INPUT_CHAR  ;GET S#
            MOVE.B D1,D3                                ;D3 HOLDS S NUMBER---------------
S_PAIRNUM   JSR INPUT_CHAR               ;GETTING FIRST DIGIT OF PAIR
            CMP.B #$39,D1
            BHI S_HEX1
            SUB.B #$30,D1                             ;D0 HOLDS PAIRS ;CHECK IF IT IS ABOVE 9, IF IT IS CONVER TO HEX BY SUBTRACTING #$37 INSTEAD OF #$30
            BRA S_STOREP1
S_HEX1      SUB.B #$37,D1      
S_STOREP1   ADD.B D1,D0
            ROL.B #4,D0

            JSR INPUT_CHAR              ;GETTING SECOND DIGIT OF PAIR
            CMP.B #$39,D1
            BHI S_HEX2
            SUB.B #$30,D1                             ;D0 HOLDS PAIRS ;CHECK IF IT IS ABOVE 9, IF IT IS CONVER TO HEX BY SUBTRACTING #$37 INSTEAD OF #$30
            BRA S_STOREP2
S_HEX2      SUB.B #$37,D1      
S_STOREP2   ADD.B D1,D0
            MOVE.L  #$00,A0
            
S_DECISIONS 
;FOR S0 RECORD
            IF.B D3 <EQ> #$30 THEN.L        ;IF  S#==0
                WHILE.B D0 <NE> #$00 DO.L   ;IGNORE # OF HEX PAIRS
                    JSR INPUT_CHAR
                    JSR INPUT_CHAR
                    SUB.B #$01,D0
                ENDW
                BRA S_GET
                
            ENDI
;FOR S2 RECORD     
            IF.B D3 <EQ> #$32 THEN.L    
                MOVE.L  #$00,D7
                MOVE.L  #$00,D4
                MOVE.L  #$00,A4
S_GET2ADD       WHILE.B D7 <NE> #$05 DO.L       ;D4 IS THE ADDRESS UNTIL IT CAN BE MOVED INTO A4
                    JSR INPUT_CHAR               ;GETTING FIRST 5 DIGITS OF ADDRESS
                    CMP.B #$39,D1
                    BHI S_HEX3
                    SUB.B #$30,D1                
                    BRA S_STOREA3
S_HEX3              SUB.B #$37,D1      
S_STOREA3           ADD.B D1,D4
                    ROL.L #4,D4
                    ADD.B #$01,D7
                ENDW

                JSR INPUT_CHAR              ;GETTING 6TH DIGIT OF ADDRESS
                CMP.B #$39,D1
                BHI S_HEX4
                SUB.B #$30,D1
                BRA S_STOREA4
S_HEX4          SUB.B #$37,D1      
S_STOREA4       ADD.B D1,D4                                        
                SUB.B #$03,D0
                
                MOVE.L  D4,A4     ;A4 IS THE DATA LOCATION;A4 IS THE DATA LOCATION;A4 IS THE DATA LOCATION
                MOVE.L  #$00,D4             
S_GETANDSTORE   WHILE.B D0 <NE> #$01 DO.L
                    JSR INPUT_CHAR              ;GETTING FIRST OF TWO NIBBLES FOR BYTE
                    CMP.B #$39,D1
                    BHI S_HEX5
                    SUB.B #$30,D1
                    BRA S_STORED5
S_HEX5              SUB.B #$37,D1      
S_STORED5           ADD.B D1,D4
                    ROL.B #4,D4
                                        
                    JSR INPUT_CHAR              ;GETTING SECOND OF TWO NIBBLES FOR A BYTE
                    CMP.B #$39,D1
                    BHI S_HEX6
                    SUB.B #$30,D1
                    BRA S_STORED6
S_HEX6              SUB.B #$37,D1      
S_STORED6           ADD.B D1,D4
                    
                    MOVE.B  D4,(A4)+             ;A4 IS THE DATA LOCATION                                        
                    SUB.B   #$01,D0
                    MOVE.L  #$00,D4
                ENDW                      
S_TRASHSUM      JSR INPUT_CHAR
                JSR INPUT_CHAR              ;GETTING JUNKSUM
                BRA S_GET                                                     
            ENDI
;FOR S8 RECORD
            IF.B D3 <EQ> #$38 THEN.L            ;IF S#==8
                MOVE.L  #$00,D7
                MOVE.L  #$00,D4
                MOVE.L  #$00,A4
S_GET8ADD       WHILE.B D7 <NE> #$05 DO.L       ;D4 IS THE ADDRESS OFFSET
                    JSR INPUT_CHAR               ;GETTING FIRST 5 DIGITS OF ADDRESS
                    CMP.B #$39,D1
                    BHI S_HEX7
                    SUB.B #$30,D1                
                    BRA S_STOREA7
S_HEX7              SUB.B #$37,D1      
S_STOREA7           ADD.B D1,D4
                    ROL.L #4,D4
                    ADD.B #$01,D7
                ENDW

                JSR INPUT_CHAR              ;GETTING 6TH DIGIT OF ADDRESS
                CMP.B #$39,D1
                BHI S_HEX8
                SUB.B #$30,D1
                BRA S_STOREA8
S_HEX8          SUB.B #$37,D1      
S_STOREA8       ADD.B D1,D4                                        
                SUB.B #$03,D0
                JSR INPUT_CHAR              ;GETTING JUNKSUM
                JSR INPUT_CHAR              ;GETTING JUNKSUM
                MOVE.L  D4,A3               ;A3 WILL HOLD THE STARTING LOCATION FOR RUNNING THE SRECORD
            ENDI
                ;STORE ADDRESS IN A3
                ;GET AND DUMP CHECK SUM        
S_FIN       LEA SREND,A1
            JSR OUTS
            MOVE.L	(A7)+,A1
            RTS
;-------------------------------------  SRECORD ENDS     --------------------------------------------------;
;DISPLAYS HELP
START_HELP	MOVE.L	A1,-(A7)
			LEA START_HELP0,A1
			JSR	OUTS
			LEA	START_HELP1,A1
			JSR	OUTS
			LEA	START_HELP2,A1
			JSR	OUTS
			LEA	START_HELP3,A1
			JSR	OUTS
			LEA	START_HELP4,A1
			JSR	OUTS
			LEA	START_HELP5,A1
			JSR	OUTS
			LEA	START_HELP6,A1
			JSR	OUTS	
			LEA	START_HELP7,A1
			JSR	OUTS
			LEA	START_HELP8,A1
			JSR	OUTS
			LEA	START_HELP9,A1
			JSR	OUTS			
			MOVE.L	(A7)+,A1
			RTS		


;OUTPUTS STRING
OUTS		MOVE.L	D0,-(A7)		;MAKE SURE THAT THE LOCATION OF THE STRING IS IN A1 WHEN PUTTING THROUGH			
			MOVE.L	D1,-(A7)		;EXAMPLE: LEA STRINGNAME,A1 THEN JSR OUTS
CONT1		MOVE.B	(A1)+,D0		;PUT NEXT LETTER OF STRING INTO D0
			MOVE.B	#$04,D1			;PUT END OF LINE CHARACTER IN D1 FOR COMPARISON
			CMP.B		D0,D1			;COMPARE CURRENT LETTER TO EOL
			BEQ		DONE1			;IF ITS EQUAL,TO EOL, RETURN TO MAIN AND REMOVE VARS FROM STACK
			JSR 	PUT_CHAR		;IF ITS NOT EQUAL, OUTPUT THE CHARACTER
			BRA		CONT1			;CONTINUE THE LOOP UNTIL EOL REACHED
DONE1	  	MOVE.L	(A7)+,D1		;RESTORE D1 AND D0 FROM STACK
			MOVE.L	(A7)+,D0		
			RTS						;RETURN TO MAIN
            
NEWLINE		MOVE.L	A1,-(A7)
			MOVE.L	D0,-(A7)
			MOVE.B	#$0A,D0			;OUTPUTS LINEFEED
			JSR 	PUT_CHAR		
			MOVE.B	#$0D,D0			;OUTPUTS CARRIAGE RETURN
			JSR 	PUT_CHAR
			MOVE.L	(A7)+,D0
			MOVE.L	(A7)+,A1
			RTS
        
    *Outputs a single character in D0 to port A
PUT_CHAR	IF.B	SIM <EQ> #00 THEN.L
	        MOVE.L	A0,-(A7)	Save working register
			LEA		DUART,A0	A0 points to DUART base address
Output_poll	BTST.B	#$02,SRA(A0) Test transmitter ready status
			BEQ		Output_poll UNTIL transmitter ready
			MOVE.B	D0,TBA(A0)	Transmit the character from port A
			MOVE.L	(A7)+,A0	Restore working register	
        	ELSE
        	MOVE.L  D1,-(A7)
        	MOVE.B	D0, D1	
        	MOVE.L	#06, D0	
        	TRAP	#15		
            MOVE.L  D1,D0
            MOVE.L  (A7)+,D1
	        ENDI
	        RTS


INPUT_CHAR	IF.B	SIM <EQ> #00 THEN.L
	        MOVE.L	A0,-(A7)	Save working register
			LEA		DUART,A0	A0 points to DUART base address
Input_poll	BTST.B	#$00,SRA(A0)	Test transmitter ready status
			BEQ		Input_poll UNTIL transmitter ready
			MOVE.B	RBA(A0),D1	Transmit the character from port A to D1
			MOVE.L	(A7)+,A0	Restore working register
	        ELSE
	        MOVE.L  D0,-(A7)
	        MOVE.L	#05, D0
	        TRAP		#15		
  	        MOVE.L  (A7)+,D0
            ENDI
	        RTS
    

INIT_DUART  LEA	  	DUART,A0		A0 points to base DUART address

; Software reset:
      	    MOVE.B	#$30,CRA(A0)	Reset TxA
		    MOVE.B	#$20,CRA(A0)	Reset RxA
		    MOVE.B	#$10,CRA(A0)	Reset MRA pointer

; Initialization:
            MOVE.B  	#$80,ACR(A0)	selects baud rate set 2
            MOVE.B  	#BAUD,CSRA(A0)  	set 19.2k baud Rx/Tx
      	    MOVE.B  	#$13,MR1A(A0)   	8-bits, no parity, 1 stop bit

; This is the most important register to set in the 68681 DUART.
; 07 sets: Normal mode, CTS and RTS disabled, stop bit length = 1
; For testing load $#47 to enable auto-echo
      	    MOVE.B	#$07,MR2A(A0)	

      	    MOVE.B	#$05,CRA(A0)	enable Tx and Rx
      	    RTS


;--------------------------------------;
START_HELP0	DC.B	'---///COMMANDS\\\---',LF,CR,$04
START_HELP1 DC.B	'Memory Dump: MD->[ENTER]->LOCATION->[ENTER]',LF,CR,$04
START_HELP2 DC.B	'Memory Modify: MM->[ENTER]->LOCATION->[ENTER]->VALUE->[ENTER]',LF,CR,$04
START_HELP3 DC.B	'Register Dump: RD->[ENTER]->LOCATION->[ENTER]',LF,CR,$04
START_HELP4 DC.B	'Register Modify: RM->[ENTER]->LOCATION->[ENTER]->VALUE->[ENTER], modifies one register.',LF,CR,$04
START_HELP5 DC.B	'For MD, enter to continue and Q to stop',LF,CR,$04
START_HELP6 DC.B	'For MM, values are continued to be changed every enter. Press Q to stop',LF,CR,$04
START_HELP7 DC.B	'SRECORD-HIT S AND THEN COPY IN S RECORD. SD TO RUN SRECORD',LF,CR,$04
START_HELP8 DC.B	'Enter "H" to see this menu again.',LF,CR,$04
START_HELP9 DC.B	'Use Caps Lock for all commands....Q WILL EXIT MD',LF,CR,$04

MAINMESS	DC.B	'---MAIN---',LF,CR,$04
MEMDUMP		DC.B	'---MEMORY DUMP---',LF,CR,$04
MEMMOD		DC.B	'---MEMORY MODIFY---',LF,CR,$04
REGDUMP		DC.B	'---REGISTER DUMP---',LF,CR,$04
REGMOD		DC.B	'---REGISTER MODIFY---',LF,CR,$04
SREC		DC.B	'---S-RECORD---',LF,CR,$04
SRSTRT      DC.B    'PLEASE COPY IN SRECORD',LF,CR,$04
SREND      DC.B    'S UPLOAD COMPLETE',LF,CR,$04

RMWARN      DC.B    '--UNABLE TO MODIFY  D0-D3,D7,A0-A3,AND A7',LF,CR,$04
INVALIDSTATEMENT DC.B	'INVALID COMMAND',LF,CR,$04

;--------------------------------------;
HELLO		DC.B	'CAME IN LIKE A WRECKING BALL',LF,CR,$04


; *******************************************************************
; Constants:	(Note the offsets to account for no A0)
DUART   	EQU	    $20000     loaded in A0 when needed, regs are offsets
MR1A   	    EQU   	1	        Mode Register1
MR2A  	    EQU   	1	        points here after MR1A is set
SRA    	    EQU   	3           Status Register (read)
CSRA   	    EQU   	3           Clock Select Register
CRA   	    EQU   	5	        Command Register
BRG         EQU     5           BGR Test Mode
TBA		    EQU   	7           Transfer Holding Register
RBA		    EQU   	7	        Receive Holding Register
ACR		    EQU	  	9	        Auxiliary control register
RxRDY		EQU		0	        Recieve ready bit position
TxRDY		EQU		2	        Transmit ready bit position
BAUD        EQU     $CC         baud rate value = 115.2k
CR          EQU     $0D         ASCII Code for CR character
LF          EQU     $0A         ASCII Code for LF character
SUPERSTACK EQU      $10800	    RAM LOCATION

SIM	        EQU	    0		;0 = hardware state, 1 = simulation state
; *******************************************************************

			
			END MAIN

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
