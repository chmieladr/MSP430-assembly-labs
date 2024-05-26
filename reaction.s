#include "msp430.h"                     ; #define controlled include file
 
        NAME    main                    ; module name
 
        PUBLIC  main                    ; make the main label vissible
                                        ; outside this module
 
        ORG     0FFEAh
        DC16    TIMER_A1_Interrupt      ; set Timer A1 Interrupt vector
        ORG     0FFE8h                  
        DC16    PORT1_isr               ; set PORT1 Interrupt vector
        ORG     0FFFEh
        DC16    init                    ; set reset vector to 'init' label
 
        RSEG    CSTACK                  ; pre-declaration of segment
        RSEG    CODE                    ; place program in 'CODE' segment
 
init:   MOV     #SFE(CSTACK), SP        ; set up stack
        MOV     #100, R11               ; pseudorandomiser initialisation
        MOV     #0, R3                  ; clearing potential dump data stored in variables
        MOV     #0, R4
        MOV     #0, R5
        MOV     #0, R6
        MOV     #0, R7
        MOV     #0, R8
        MOV     #0, R9
        MOV     #0, R10             
        MOV     #0, R12
        MOV     #0, R13
        MOV     #0, R14
        MOV     #0, R15
 
main:   NOP                             ; main program
        MOV.W   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
        
        mov.w   #800, &TACCR0           ; Period for up mode = ~ 0.01 s
        mov.w   #CCIE, &TACCTL1         ; Enable interrupts on Compare 0
        BIS.B   #0xFF, &P2DIR           ; set P2 as output
        MOV.B   #FFh, P2OUT             ; set the output to 0xFF to make sure the display is off
 
        ; Set up Timer A. Up mode, divide clock by 8, clock from SMCLK, clear TAR
        mov.w   #MC_1|ID_3|TASSEL_2|TACLR, &TACTL
        
        MOV.B   #1111b, P1IE            ; P1.3 interrupt enabled
        MOV.B   #1111b, P1IES           ; P1.3 Hi/lo edge
        BIC.B   #1111b, P1IFG           ; IFG cleared
        bis.w   #GIE, SR                ; Enable interrupts (just TACCR0)
 
        JMP $                           ; jump to current location '$'
                                        ; (endless loop)

; PORT1 interrupt responsible for handling the buttons
PORT1_isr:
        CMP.B   #1, R15 ; if currently busy, skip the interrupt
        JZ      currently_busy
        MOV.B   P4IN, R10 ; take the input from buttons
        MOV     #0, R12 ; clear dump variables from previous state
        MOV     #0, R13
        MOV.B   #00000010b, R12 ; check for INIT state      
        AND.B   R10, R12
        MOV.B   #00000001b, R13 ; check for STOP state
        AND.B   R10, R13
currently_busy:
        BIC.B   #1111b, P1IFG ; IFG cleared
        RETI

; counter stored in R14 register (later forwarded to R4 to correctly process the output)
; pseudorandomiser stored in R11 register
TIMER_A1_Interrupt: 
        CMP     #1, R15 ; if busy flag set
        JNZ     not_busy
        DEC     R8 ; decrement the stored random value
        CMP     #0, R8 ; if the stored random value reaches 0
        JNZ     routine ; skip the rest of logic while still waiting for the light
        MOV.B   #0, R15 ; clear the busy flag
        MOV.B   #1, R9 ; set the calc_time flag
        JMP     routine
not_busy:
        CMP     #00000010b, R12 ; if INIT state reached
        JNZ     skip_init ; if not then skip starting procedure
        MOV.B   #FFh, P2OUT ; set the output to 0xFF to clear the display
        MOV.B   R11, R8 ; store a random value in R8
        MOV.B   #1, R15 ; set the busy flag
        CLR     R12 ; clear the INIT state after handled
skip_init:
        CMP     #00000001b, R13 ; if STOP state received
        JNZ     routine ; if not then skip displaying the time logic
        CMP     #100, R3 ; if the user was slower than a second
        JLO     fast_enough ; skip if the user wasn't too slow
        MOV.B   #99, R3 ; set the display time to 0.99 sec if the user was too slow
fast_enough:
        MOV     R3, R4 ; move the timer to be displayed
        CALL    #nkb2bcd ; convert the value to 7 segment display
        CLR     R9 ; clear the calc_time flag after handled
routine: ; mostly handles pseudorandomiser logic
        INC     R11 ; always increment the pseudorandomiser
        CMP     #1, R9 ; if calc_time flag is set
        JNZ     skip_calc_time ; if not then skip
        INC     R3 ; calculate the time
skip_calc_time:
        CMP     #600, R11 ; if the randomiser reaches 6 secs (logic that handles 1 - 6 sec range)
        JNZ     skip_rand_reset ; if not then skip
        MOV.B   #100, R11 ; reset the randomiser to 1 sec
skip_rand_reset:
        BIC     #CCIFG, &TACCTL1        
        RETI

; function that converts hex number to 7 segment display fixing the issues with displaying hex 0xA-F digits
; R4 - number to convert
; used registers: R4, R5, R6, R7
; source: https://monjino.atlassian.net/wiki/spaces/TM/pages/1210482707/Lab+4.+wiczenie
nkb2bcd:
        PUSH R4 ; temporarily store the number in stack
        PUSH R5
        PUSH R6
        PUSH R7
        MOV #0, R7
        MOV #0, R5
        MOV R4, R6
decimal_loop:
        CMP #10, R6
        JNC display
        ADD #10, R5
        INC R7
        SUB #10, R6
        JMP decimal_loop     
display:        
        SUB R5, R4
        RLA R7
        RLA R7
        RLA R7
        RLA R7
        ADD R7, R4
        MOV.B R4, P2OUT ; move processed value to output
        POP R7 ; clearing the stack
        POP R6
        POP R5
        POP R4
        RET
        
        END