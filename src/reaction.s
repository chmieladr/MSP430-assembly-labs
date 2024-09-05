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
        mov     #100, R11               ; pseudorandomiser initialisation
        mov     #0, R3                  ; clearing potential dump data stored in registers
        mov     #0, R4
        mov     #0, R5
        mov     #0, R6
        mov     #0, R7
        mov     #0, R8
        mov     #0, R9
        mov     #0, R10             
        mov     #0, R12
        mov     #0, R13
        mov     #0, R14
        mov     #0, R15
 
main:   nop                             ; main program
        mov.w   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
        
        mov.w   #800, &TACCR0           ; Period for up mode = ~ 0.01 s
        mov.w   #CCIE, &TACCTL1         ; Enable interrupts on Compare 0
        bis.b   #0xFF, &P2DIR           ; set P2 as output
        mov.b   #FFh, P2OUT             ; set the output to 0xFF to make sure the display is off
 
        ; Set up Timer A. Up mode, divide clock by 8, clock from SMCLK, clear TAR
        mov.w   #MC_1|ID_3|TASSEL_2|TACLR, &TACTL
        
        mov.b   #1111b, P1IE            ; P1.3 interrupt enabled
        mov.b   #1111b, P1IES           ; P1.3 Hi/lo edge
        bic.b   #1111b, P1IFG           ; IFG cleared
        bis.w   #GIE, SR                ; Enable interrupts (just TACCR0)
 
        jmp     $                       ; jump to current location '$'
                                        ; (endless loop)

PORT1_isr:                              ; PORT1 interrupt responsible for handling the buttons
        cmp.b   #1, R15                 ; if currently busy, skip the interrupt
        jz      currently_busy
        mov.b   P4IN, R10               ; take the input from buttons
        mov     #0, R12                 ; clear dump variables from previous state
        mov     #0, R13
        mov.b   #00000010b, R12         ; check for INIT state      
        and.b   R10, R12
        mov.b   #00000001b, R13         ; check for STOP state
        and.b   R10, R13
currently_busy:
        bic.b   #1111b, P1IFG           ; IFG cleared
        reti

; counter stored in R14 register (later forwarded to R4 to correctly process the output)
; pseudorandomiser stored in R11 register
TIMER_A1_Interrupt: 
        cmp     #1, R15                 ; if busy flag set
        jnz     not_busy
        dec     R8                      ; decrement the stored random value
        cmp     #0, R8                  ; if the stored random value reaches 0
        jnz     routine                 ; skip the rest of logic while still waiting for the light
        mov.b   #0, R15                 ; clear the busy flag
        mov.b   #1, R9                  ; set the calc_time flag
        jmp     routine
not_busy:
        cmp     #00000010b, R12         ; if INIT state reached
        jnz     skip_init               ; if not then skip starting procedure
        mov.b   #FFh, P2OUT             ; set the output to 0xFF to clear the display
        mov.b   R11, R8                 ; store a random value in R8
        mov.b   #1, R15                 ; set the busy flag
        clr     R12                     ; clear the INIT state after handled
skip_init:
        cmp     #00000001b, R13         ; if STOP state received
        jnz     routine                 ; if not then skip displaying the time logic
        cmp     #100, R3                ; if the user was slower than a second
        jlo     fast_enough             ; skip if the user wasn't too slow
        mov.b   #99, R3                 ; set the display time to 0.99 sec if the user was too slow
fast_enough:
        mov     R3, R4                  ; move the timer to be displayed
        call    #nkb2bcd                ; convert the value to 7 segment display
        clr     R9                      ; clear the calc_time flag after handled
routine:                                ; mostly handles pseudorandomiser logic
        inc     R11                     ; always increment the pseudorandomiser
        cmp     #1, R9                  ; if calc_time flag is set
        jnz     skip_calc_time          ; if not then skip
        inc     R3                      ; calculate the time
skip_calc_time:
        cmp     #600, R11               ; if the randomiser reaches 6 secs (logic that handles 1 - 6 sec range)
        jnz     skip_rand_reset         ; if not then skip
        mov.b   #100, R11               ; reset the randomiser to 1 sec
skip_rand_reset:
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