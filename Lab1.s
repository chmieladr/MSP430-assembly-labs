#include "msp430.h"                     ; #define controlled include file

        NAME    main                    ; module name

        PUBLIC  main                    ; make the main label vissible
                                        ; outside this module
        ORG     0FFFEh
        DC16    init                    ; set reset vector to 'init' label

        RSEG    CSTACK                  ; pre-declaration of segment
        RSEG    CODE                    ; place program in 'CODE' segment

init:   MOV     #SFE(CSTACK), SP        ; set up stack

main:   NOP                             ; main program


        MOV.W   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
gpio_config:        
        MOV.B   #0, P2OUT
        MOV.B   #255, P2DIR
loop:
        INC     R8 ; add a second each time while invoking this loop
        MOV.B   P4IN, R5 ; saving the input value from buttons to R5
        MOV.W   #0, R6 ; variable for calculating the sum
        MOV.B   #00000001b, R7 ; mask for the P4.0 button
        AND.B   R5, R7 
        CMP     #00000001b, R7 ; if button P4.0 is pressed
        JZ      check_button1
        ADD     #1, R6 ; add 1 to the sum
check_button1:
        MOV.B   #00000010b, R7 ; mask for the P4.1 button
        AND.B   R5, R7
        CMP     #00000010b, R7 ; if button P4.1 is pressed
        JZ      check_button2
        ADD.B   #2, R6 ; add 2 to the sum
check_button2:
        MOV.B   #00000100b, R7 ; mask for the P4.2 button
        AND.B   R5, R7
        CMP     #00000100b, R7 ; if button P4.2 is pressed
        JZ      check_button3
        ADD.B   #3, R6 ; add 3 to the sum
check_button3: ; button with timer
        MOV.B   #00001000b, R7 ; mask for the P4.3 button
        AND.B   R5, R7
        CMP     #00001000b, R7 ; if button P4.3 is pressed
        JZ      reset_timer ; reset the timer before we start counting pseudoseconds again
        ADD.B   #4, R6 ; add 4 to the sum
workaround: ; workaround for the 7-segment display issue with trying to display 0xA instead
        CMP     #10, R6 ; if sum equals 10
        JNZ     not_equal10 ; if not, jump to not_equal_10
        MOV.B   #16, R6 ; else replace R6 with 16
not_equal10:
        ;MOV.B   R6, P2OUT ; left-over code from previous task (2)
        MOV.B   R8, P2OUT ; send the currently calculated amount of pseudoseconds to the output
        ;MOV.B   #45h, P2OUT ; left-over code from previous task (1)
        MOV     #9999h, R4 ; R4, R9 registers used for balancing the delay
        MOV     #3, R9 ; that create an illusion of seconds (since usage of timers was disallowed for this task)
delay: ; delay loop for counting pseudoseconds
        DEC R4
        JNZ delay
        DEC R9
        JNZ delay
        JMP loop                        ; jump to gpio_config
                                        ; (endless loop)
        JMP $                           ; jump to current location '$'
                                        ; (endless loop)

reset_timer:
        ;MOV.B   R8, R6 ; left-over code from previous task (2)
        MOV.B   #0, R8 ; reset the variable that keeps the output value
        JMP     workaround
        END
