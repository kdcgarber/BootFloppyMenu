;FREHD BOOT W/OUT MODIFIED C ROM
;TJBCHRIS WROTE THIS - 11/16/2020 - UPDATED 11/2022
;kdcgarber Modified to include Retrostore and IP address 01/26
;BASED ON BASIC PROGRAM ON GITHUB: APUDER/TRS-IO ISSUE #23

;TRS-IO command values from retrostore.h
;#define TRS_IO_PORT 31
;#define TRS_IO_CORE_MODULE_ID 0
;#define TRS_IO_SEND_VERSION 0
;#define TRS_IO_SEND_STATUS 1
;#define TRS_IO_CMD_CONFIGURE_WIFI 2
;#define TRS_IO_SEND_WIFI_SSID 3
;#define TRS_IO_SEND_WIFI_IP 4

TRS_IO_PORT 			EQU	1FH	;31
TRS_IO_CORE_MODULE_ID 		EQU	00H
TRS_IO_SEND_VERSION		EQU	00H
TRS_IO_SEND_STATUS 		EQU	01H
TRS_IO_CMD_CONFIGURE_WIFI	EQU 	02H
TRS_IO_SEND_SSID		EQU	03H  	;Had to remove _WIFI because the variable was to long to for it to be unique
TRS_IO_SEND_IP 			EQU	04H



;MODEL 4-SPECIFIC EQUATE
MODEL	EQU	4	;COMPUTER MODEL

;STANDARD EQUATES
FREHD	EQU	196	;REHD PORT
MEMLOC	EQU	5000H	;WHERE TO STORE CODE FROM FREHD
NBYTES	EQU	255 	;NUM OF BYTES TO READ FROM FREHD
RSLOC   EQu     5100H   ;LOCATION OF THE RETROSTORE IN MEMORY

	;ORG ADDRESS AND BOOT TRACK FOR MODEL III/4/4P
	;USING LDOS 5.3.1 DATA DISK AS THE BASE (DIR TRACK 20)
	ORG	4300H     ;4300H for M3/M4/M4P  xxxxH for M1


START:
	NOP

CLS:
        CALL    01C9H           ;Calls the CLS routine at address 01C9h



; -- Menu ---------------------------------------------------------------------
	CALL	HEADER
        
GET_KEY:
        ; Wait for keypress and return character in A
        CALL    0049H           ; KBWAIT: ROM routine that waits for key (Model 4)
                                ; Saves 4 bytes vs manually looping CALL 002BH
        
        CP      1BH             ; Break key to exit
        RET     Z               ; 2 bytes
        
        ; Using relative subtraction for menu selection
        SUB     '1'             ; A is now 0 for '1', 1 for '2', 2 for '3'
        JR      C, GET_KEY      ; If key < '1', ignore and loop
        
        JR      Z, DO_FREHD     ; If A was 0 (key '1')
        DEC     A               ; A becomes 0 if it was 1 (key '2')
        JR      Z, DO_RETRO     
        DEC     A               ; A becomes 0 if it was 2 (key '3')
        JR      Z, DO_SHOW_IP
        
        JR      GET_KEY         ; Else loop back



; Prints characters until it hits a 03H byte
PRINT_STR:
        LD      A, (HL)
        CP      03H             ; Is it the end marker?
        RET     Z               ; If yes, return
        CALL    0033H           ; Print char in A to screen
        INC     HL              ; Move to next char
        JR      PRINT_STR



HEADER:

	; TRSNIC HEADER LARGE LETTERS
	LD	HL, TRSMSG
	CALL	PRINT_STR

	; DRAW LINE
	LD   	B,64
COUNTLP:
	LD	HL, LINE
	CALL	PRINT_STR
        DJNZ 	COUNTLP    	; B counts down from 64 to 0
        
        ; Print the Menu String
        LD      HL, MENU_TXT    
        CALL    PRINT_STR       

	RET




;----  FREHD --------------------------------------------------------------
DO_FREHD:
        CALL    01C9H           ;Calls the CLS routine at address 01C9h
        LD      HL, WAITNG   
        CALL    PRINT_STR       ; Use our custom printer below


;THE FIRST THREE SECTORS OF A BOOT DISK
;INDICATE THE LOCATION OF THE DIRECTORY.
;FOR MY DISKS...LDOS 5 (MODEL III/4): TRACK 20  = 14 Hex
;               TRSDOS 2.1 (MODEL I): TRACK 17  = 11 Hex
	CP	14H

	
; DO THE MAIN TRSNIC LOAD	
WAITFRD:
	; 10 poke 16912,56
	LD	A,56
	LD	(16912),A       ;IM NOT SURE WHAT THIS DOES, BUT IF ITS NOT THERE THEM MENU ITEMS DONT COME UP

;READ FROM FREHD PORT AND TELL IT WHICH MODEL IT IS
	;also on 10 : OUT 236,56
	OUT	(236),A
	;20 OUT 197,4  :REM 1=M1, 3=M3, 4=M3/M4A/ 5=M4P
	LD	A,MODEL
	OUT	(197),A 	;SET MODEL (1, 3, 4, 5 FOR 4P)

;CHECK FOR EXPECTED BYTE
	; 30 IF	inp(196) <> 254 STOP
	IN	A,(FREHD)	;READ BYTE FROM FREHD PORT
	CP	254
	JR	NZ,WAITFRD      ;LOOP TO START OVER IF NO FREHD THEN WAIT FOR FREHD
	


;WHEN GOOD, READ NBYTES BYTES FROM FREHD AND JUMP TO IT FOR THE FREHD MENU
	; 40 FOR I=0 TO 255: POKE 20480+I,INP(196); NEXT
	LD	HL,MEMLOC	;STARTING ADDR FOR FREHD CODE
	LD	B,NBYTES
	LD	C,FREHD
	INIR
	JP	MEMLOC
	







; ----- RetroStore ------------------------------------------------------------
; https://github.com/apuder/TRS-IO?tab=readme-ov-file#launching-the-native-retrostore-client

DO_RETRO:
        ; Set Model 4 Mode/Memory (Port 236)
        ; 10 OUT 236, 16
        LD      A, 10H
        OUT     (0ECH), A

        ; Reset/Initialize Port 31 logic
        ; 20 OUT 31, 3
        LD      A, 03H
        OUT     (TRS_IO_PORT), A
        
        ; 30 OUT 31, 1
        DEC     A               ; A becomes 02H
        SRL     A               ; A becomes 01H 
        OUT     (TRS_IO_PORT), A

        ; Port 31 "N" value consumption.  the value keeps coming to 65xxx and not the 125 needed.
        ; 50 FOR X = 1 TO N : POKE 20735 + X, INP(31) : NEXT
        ; So just slurping up these 2 reads and not doing the calc.
        IN      A, (TRS_IO_PORT)
        IN      A, (TRS_IO_PORT)

        ; Setup for Block Transfer
        LD      HL, RSLOC       ; Destination address
        LD      B, 125          ; Loop count (N=125) just forcing it to 125
        LD      C, TRS_IO_PORT       ; Port address (31)

READ_LOOP:
        INI                     ; (HL) <- Port(C), HL++, B--
        JR      NZ, READ_LOOP   ; Loop until B is 0

        ; Jump to loaded code
        JP      RSLOC           








; ----- IP address of the trs-nic ------------------------------------------------------------
; example from https://github.com/apuder/TRS-IO?tab=readme-ov-file#configuring-trs-io
DO_SHOW_IP

	CALL	HEADER			; CLS AND PUT UP HEADER INFO SO THE SCREEN IS CLEAN.

        ; 10 OUT 236,16
        LD      A,10H            ; Load 16 (hex 10) into accumulator
        OUT     (0ECH),A         

        ; 20 OUT 31,0 : OUT 31,4
        XOR     A                	; Clear A (A = 0)
        OUT     (TRS_IO_PORT),A       	; OUT 31,0
        LD      A,TRS_IO_SEND_IP	;TRS_IO_SEND_IP =  04H
        OUT     (TRS_IO_PORT),A       	; OUT 31,4

IP_LOOP:
        ; 30 C=INP(31) : IF C=0 THEN GOTO 60
        IN      A,(TRS_IO_PORT)       	; Read port 31 into A  C=INP(31)
        
        ; CHECK FOR END
        OR      A                	; Is the character 0
	JP      Z, GET_KEY       	; If yes, JUMP TO MENU TO START OVER

	CP 	3AH       		; MOVE TO NEXT IF VALUE IS A < 39H, which would be anthing to print
	JR 	NC, IP_LOOP   		; NC = A >= 39h
	
        ; 40 PRINT CHR$(C)        
        CALL    0033H            ; ROM routine to print char in A

        ; 50 GOTO 30
        JR      IP_LOOP          ; Repeat the loop
 



	
;---- STRING CONSTANTS -------------------------------------------------------
WAITNG  DB	'Waiting..',03H
;TRG3ROM	DB	0CDH,03H,00H	;Coax 4P into loading MODELA/III
MENU_TXT:
        DB	"1 FreHD", 0DH
        DB      "2 RetoStore", 0DH
        DB      "3 IP:", 03h

TRSMSG  DB	1CH          ; Clear the screen using the Control Code 1CH
	;  T                 R                 S                 N                 I                 C
	DB 131,191,131," ",  191,131,189," ",  167,147,139," ",  191,148,191," ",  131,191,131," ",  191,131,131,  0DH
	DB 128,191,128," ",  191,131,189," ",  180,178,185," ",  191,138,191," ",  176,191,176," ",  191,176,176,  0DH,03H

LINE    DB 140,3   ; chacter to make the solid line

	END	START
	
	
	
