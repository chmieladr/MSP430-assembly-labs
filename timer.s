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
 
init:   mov     #SFE(CSTACK), SP        ; set up stack
        mov     #0, R4                  ; clearing potential dump data stored in variables
        mov     #0, R5
        mov     #0, R6
        mov     #0, R7
        mov     #0, R10             
        mov     #0, R11
        mov     #0, R12
        mov     #0, R13
        mov     #0, R14
 
main:   nop                             ; main program
        mov.w   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
        
        mov.w   #65535, &TACCR0         ; Period for up mode
        mov.w   #CCIE, &TACCTL1         ; Enable interrupts on Compare 0
        bis.b   #0xFF, &P2DIR           ; Set P2 to output
        mov.b   0, P2OUT                ; Clear the dump data in output

        ; Set up Timer A. Up mode, divide clock by 8, clock from SMCLK, clear TAR
        mov.w   #MC_1|ID_3|TASSEL_2|TACLR, &TACTL
        
        mov.b   #1111b, P1IE            ; P1.3 interrupt enabled
        mov.b   #1111b, P1IES           ; P1.3 Hi/lo edge
        bic.b   #1111b, P1IFG           ; IFG cleared
        bis.w   #GIE, SR                ; Enable interrupts (just TACCR0)
 
        jmp     $                       ; jump to current location '$'
                                        ; (endless loop)

PORT1_isr:                              ; PORT1 interrupt responsible for handling the buttons
        mov.b   P4IN, R10               ; take the input from buttons
        mov     #0, R11                 ; clear dump variables from previous state
        mov     #0, R12
        mov     #0, R13
        mov.b   #00000100b, R11         ; check for START state
        and.b   R10, R11
        mov.b   #00000010b, R12         ; check for STOP state      
        and.b   R10, R12
        mov.b   #00000001b, R13         ; check for RESET state
        and.b   R10, R13
        bic.b   #1111b, P1IFG           ; IFG cleared
        RETI

; counter stored in R14 register (later forwarded to R4 to correctly process the output)
TIMER_A1_Interrupt:
        cmp     #00000001b, R13         ; if RESET state received
        jz      skip_reset              ; if not then skip
        clr     R14                     ; clear the counter
        mov     #0, R13                 ; clear the RESET state
skip_reset:
        cmp     #00000010b, R12         ; if STOP state reached
        jz      skip_decr               ; if not then skip the decrementation
        dec     R14                     ; decrement the counter (INC along with DEC results in no changes)
        jmp     routine
skip_decr:
        cmp     #00000100b, R11         ; if START state received
        jnz     routine                 ; if not then skip clearing the states
        clr     R12                     ; upon starting, clear the STOP state
        clr     R11                     ; and the START state since it has already started
routine:
        inc     R14                     ; always increment (even if it's stopped)
        mov.b   R14, R4                 ; moving the value of counter to be displayed
        call    #nkb2bcd                ; convert that value to 7 segment display
        bic     #CCIFG, &TACCTL1        
        reti

; function that converts hex number to 7 segment display fixing the issues with displaying hex 0xA-F digits
; R4 - number to convert
; used registers: R4, R5, R6, R7
; source: https://monjino.atlassian.net/wiki/spaces/TM/pages/1210482707/Lab+4.+wiczenie
nkb2bcd:
        push    R4                      ; temporarily store the number in stack
        push    R5
        push    R6
        push    R7
        mov     #0, R7
        mov     #0, R5
        mov     R4, R6
decimal_loop:
        cmp     #10, R6
        jnc     display
        add     #10, R5
        inc     R7
        sub     #10, R6
        jmp     decimal_loop     
display:        
        sub     R5, R4
        rla     R7
        rla     R7
        rla     R7
        rla     R7
        add     R7, R4
        cmp     #A0h, R4                ; upon reaching 100 (which is hex 0xA0 after conversion)
        jz      skip_count_reset        ; if not then skip
        mov     #0, R4                  ; reset the counter
skip_count_reset:
        mov.b   R4, P2OUT
        pop     R7                      ; clearing the stack
        pop     R6
        pop     R5
        pop     R4
        ret
        
        END