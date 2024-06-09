#include "msp430.h"                     ; #define controlled include file

        NAME    main                    ; module name

        PUBLIC  main                    ; make the main label vissible
                                        ; outside this module
        ORG     0FFFEh
        DC16    init                    ; set reset vector to 'init' label

        RSEG    CSTACK                  ; pre-declaration of segment
        RSEG    CODE                    ; place program in 'CODE' segment

init:   mov     #SFE(CSTACK), SP        ; set up stack

main:   nop                             ; main program
        mov.w   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
gpio_config:        
        mov.b   #0, P2OUT
        mov.b   #255, P2DIR
loop:
        inc     R8                      ; add a second each time while invoking this loop
        mov.b   P4IN, R5                ; saving the input value from buttons to R5
        mov.w   #0, R6                  ; variable for calculating the sum
        mov.b   #00000001b, R7          ; mask for the P4.0 button
        and.b   R5, R7 
        cmp     #00000001b, R7          ; if button P4.0 is pressed
        jz      check_button1
        add     #1, R6                  ; add 1 to the sum
check_button1:
        mov.b   #00000010b, R7          ; mask for the P4.1 button
        and.b   R5, R7
        cmp     #00000010b, R7          ; if button P4.1 is pressed
        jz      check_button2
        add.b   #2, R6                  ; add 2 to the sum
check_button2:
        mov.b   #00000100b, R7          ; mask for the P4.2 button
        and.b   R5, R7
        cmp     #00000100b, R7          ; if button P4.2 is pressed
        jz      check_button3
        add.b   #3, R6                  ; add 3 to the sum
check_button3:                          ; button with timer
        mov.b   #00001000b, R7          ; mask for the P4.3 button
        and.b   R5, R7
        cmp     #00001000b, R7          ; if button P4.3 is pressed
        jz      reset_timer             ; reset the timer before we start counting pseudoseconds again
        add.b   #4, R6                  ; add 4 to the sum
workaround:                             ; workaround for the 7-segment display issue with trying to display 0xA instead
        cmp     #10, R6                 ; if sum equals 10
        jnz     not_equal10             ; if not, jump to not_equal_10
        mov.b   #16, R6                 ; else replace R6 with 16
not_equal10:
        ;mov.b   R6, P2OUT              ; left-over code from previous task (2)
        mov.b   R8, P2OUT               ; send the currently calculated amount of pseudoseconds to the output
        ;mov.b   #45h, P2OUT            ; left-over code from previous task (1)
        mov     #9999h, R4              ; R4, R9 registers used for balancing the delay
        mov     #3, R9                  ; that create an illusion of seconds (since usage of timers was disallowed for this task)
delay:                                  ; delay loop for counting pseudoseconds
        dec     R4
        jnz     delay
        dec     R9
        jnz     delay
        jmp     loop                    ; jump to gpio_config
                                        ; (endless loop)
        jmp     $                       ; jump to current location '$'
                                        ; (endless loop)

reset_timer:
        ;mov.b   R8, R6                 ; left-over code from previous task (2)
        mov.b   #0, R8                  ; reset the variable that keeps the output value
        jmp     workaround

        END