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
        MOV     #0, R4                  ; clearing potential dump data stored in variables
        MOV     #0, R5
        MOV     #0, R6
        MOV     #0, R7
        MOV     #0, R10             
        MOV     #0, R11
        MOV     #0, R12
        MOV     #0, R13
        MOV     #0, R14
 
main:   NOP                             ; main program
        MOV.W   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
        
        mov.w   #65535, &TACCR0         ; Period for up mode
        mov.w   #CCIE, &TACCTL1         ; Enable interrupts on Compare 0
        BIS.B   #0xFF, &P2DIR           ; Set P2 to output
        MOV.B   0, P2OUT                ; Clear the dump data in output

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
        MOV.B   P4IN, R10 ; take the input from buttons
        MOV     #0, R11 ; clear dump variables from previous state
        MOV     #0, R12
        MOV     #0, R13
        MOV.B   #00000100b, R11 ; check for START state
        AND.B   R10, R11
        MOV.B   #00000010b, R12 ; check for STOP state      
        AND.B   R10, R12
        MOV.B   #00000001b, R13 ; check for RESET state
        AND.B   R10, R13
        BIC.B   #1111b, P1IFG ; IFG cleared
        RETI

; counter stored in R14 register (later forwarded to R4 to correctly process the output)
TIMER_A1_Interrupt:
        CMP     #00000001b, R13 ; if RESET state received
        JZ      skip_reset ; if not then skip
        CLR     R14 ; clear the counter
        MOV     #0, R13 ; clear the RESET state
skip_reset:
        CMP     #00000010b, R12 ; if STOP state reached
        JZ      skip_decr ; if not then skip the decrementation
        DEC     R14 ; decrement the counter (INC along with DEC results in no changes)
        JMP     routine
skip_decr:
        CMP     #00000100b, R11 ; if START state received
        JNZ     routine ; if not then skip clearing the states
        CLR     R12 ; upon starting, clear the STOP state
        CLR     R11 ; and the START state since it has already started
routine:
        INC     R14 ; always increment (even if it's stopped)
        MOV.B   R14, R4 ; moving the value of counter to be displayed
        call    #nkb2bcd ; convert that value to 7 segment display
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
        CMP #A0h, R4 ; upon reaching 100 (which is 0xA0 after conversion)
        JZ skip_count_reset ; if not then skip
        MOV #0, R4 ; reset the counter
skip_count_reset:
        MOV.B R4, P2OUT
        POP R7 ; clearing the stack
        POP R6
        POP R5
        POP R4
        RET
        
        END