#include "msp430.h"                     ; #define controlled include file

        NAME    main                    ; module name

        PUBLIC  main                    ; make the main label vissible
                                        ; outside this module

        ORG     0FFE8h                  
        DC16    PORT1_isr               ; set PORT1 Interrupt vector
        ORG     0FFFEh
        DC16    init                    ; set reset vector to 'init' label

        RSEG    CSTACK                  ; pre-declaration of segment       
        RSEG    CODE                    ; place program in 'CODE' segment

init:   MOV     #SFE(CSTACK), SP        ; set up stack
        MOV     #6, R4                  ; setting the default output value
        MOV.B   R4, P2OUT               ; and instantly displaying it

main:   NOP                             ; main program
        MOV.W   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
        
        MOV.B   #255,P2DIR              ; set all pins from port 2 as outputs
        MOV.B   #0, P2OUT               ; set port 2 to low
        MOV.B   #11b, P1IE              ; P1.0 interrupt enabled
        MOV.B   #11b, P1IES             ; P1.0 Hi/lo edge
        BIC.B   #11b, P1IFG             ; IFG cleared
        bis.w   #GIE, SR                ; Enable global interrupts
        
        JMP $                           ; jump to current location '$'
                                        ; (endless loop)

; PORT1 Interrupt handling the encoder
PORT1_isr:
        MOV.B   P1IN, R5 ; get the encoder input
        MOV.B   #0100b, R6 ; check which way it was moved
        AND.B   R5, R6
        CMP     #0100b, R6
        JNZ     moved_right
        DEC     R4 ; if moved left, decrement R4
        JMP     moved_left
moved_right:
        INC     R4 ; if moved right, increment R4
moved_left:
        MOV.b   #5, R7 ; check if R4 is less than 6 (encoder can only move by 1 so it's enough to check if it's equal to 5)
        CMP     R4, R7
        JNZ     more_than_five ; if not then skip the incrementation
        INC     R4 ; if R4 is less than 5, increment it to make it back equal to 6
more_than_five:
        MOV.b   #13, R7 ; check if R4 is more than 12 (enough for the same reason as above)
        CMP     R4, R7
        JNZ     display ; if not then go to display
        DEC     R4
display:
        MOV.B   #9, R7 ; check if R4 is less than 10 as values higher than 9
        CMP     R4, R7 ; require a fix that prevents them from an attempt of being displayed incorrectly as hexadecimal
        JN      more_than_nine
        JMP     routine
more_than_nine: ; adding 6 if more than 9 since 16 = 0x10, 17 = 0x11 and so on...
        ADD.B   #6, P2OUT ; as a result 10, 11 etc. shows up instead of display failing the attempt to display 0xA, 0xB and so on...
routine:
        MOV.B   R4, P2OUT ; move the value to output
        BIC.B   #11b,   P1IFG           ; IFG cleared
        RETI                            ; Return from Interrupt Service Routine

        END