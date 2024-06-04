#include "msp430.h"                     ; #define controlled include file
 
        NAME    main                    ; module name

        PUBLIC  main                    ; make the main label vissible
                                        ; outside this module
        ORG     0FFECh
        DC16    TIMER_A0_Interrupt
        ORG     0FFFEh                  
        DC16    init                    ; set reset vector to 'init' label
 
        RSEG    CSTACK                  ; pre-declaration of segment
        RSEG    CODE                    ; place program in 'CODE' segment

BUFF    EQU     0200h                   ; buffer address for ADC samples

init:   mov     #SFE(CSTACK), SP        ; set up stack
        mov.b   #255, P2DIR             ; set all pins from port 2 as outputs
        mov.b   #0, P2OUT               ; set port 2 to low

        ; Buffer initialization (and helper pointers)
        mov     #BUFF, R15              ; R15 = #BUFF | always points to the beginning of the buffer
        mov     #BUFF, R4               ; R4 = #BUFF | points to the current location in the buffer
        mov     #128, R5                ; R5 = 128 | current number of non-assigned slots in the buffer
        mov     #0, R12                 ; R12 = 0 | current position in the buffer (while storing)
 
; ADC config (based on documentation)
        bis.w   #0000100011110000b, &ADC12CTL0
        ; SHT0 = 1000b (256 cycles) | MSC = 1 | REF2_5V = 1 | REFON = 1 | ADC12ON = 1
        bis.w   #0000001000000010b, &ADC12CTL1
        ; SHP = 1 | CONSEQ2 = 1 -> A1 goes to MEM0
        bis.b   #00000001b, &ADC12MCTL0 ; set input channel as A1
        bis.b   #10b, &P6SEL ; set P6.1 as analog input
        bis.w   #11b, &ADC12CTL0 ; has to be at the end
        ; ENC = 1 | ADC12SC = 1 -> enables and starts conversion
 
; Basic Clock Module Initialisation
; - switch from DCO to XT2
; - MCLK & SMCLK supplied from XT2, ACLK = n/a
; - the DCO is left runing
        bis.b   #OSCOFF, SR             ; turn OFF osc.1
        bic.b   #XT2OFF, BCSCTL1        ; turn ON osc.2
BCM0    bic.b   #OFIFG, &IFG1           ; clear OFIFG
        mov     #0FFFFh, R15            ; delay (waiting for oscilator start)
BCM1    dec     R15                     ; delay
        ; jnz BCM1                      ; delay -> commented out as it was ocasionally leading to infinite loop
        bit.b   #OFIFG, &IFG1           ; test OFIFG
        jnz     BCM0                    ; repeat test if needed
; MCLK
        bic.b   #040h, &BCSCTL2         ; select XT2CLK as source
        bis.b   #080h, &BCSCTL2         ;
        bic.b   #030h, &BCSCTL2         ; MCLK=source/1 (8MHz)
; SMCLK
        bis.b   #SELS, &BCSCTL2         ; select XT2CLK as source
        bic.b   #006h, &BCSCTL2         ; SMCLK=source/1 (8MHz)
 
; DAC_0 initialisation 
        bis.w #REFON+REF2_5V, &ADC12CTL0; Reference generator ON, VRef+=2.5V
        bic #DAC12SREF0, &DAC12_0CTL    ; set Vref=VREF+
        bic #DAC12SREF1, &DAC12_0CTL    ;
        bic #DAC12RES, &DAC12_0CTL      ; 12-bit resolution
        bic #DAC12LSEL0, &DAC12_0CTL    ; Load mode 0
        bic #DAC12LSEL1, &DAC12_0CTL    ;
        bis #DAC12IR, &DAC12_0CTL       ; Full-Scale=1xVref
        bis #DAC12AMP0, &DAC12_0CTL     ; High speed amplifier output 
        bis #DAC12AMP1, &DAC12_0CTL     ;
        bis #DAC12AMP2, &DAC12_0CTL     ;
        bic #DAC12DF, &DAC12_0CTL       ; Data format - straight binary 
        bic #DAC12IE, &DAC12_0CTL       ; Interrupt disabled 
        bis #DAC12ENC, &DAC12_0CTL      ; DAC_0 conversion enabled 
 
; DAC_1 initialisation 
        bis.w #REFON+REF2_5V, &ADC12CTL0; Reference generator ON, VRef+=2.5V
        bic #DAC12SREF0, &DAC12_1CTL    ; set Vref=VREF+
        bic #DAC12SREF1, &DAC12_1CTL    ;
        bic #DAC12RES, &DAC12_1CTL      ; 12-bit resolution
        bic #DAC12LSEL0, &DAC12_1CTL    ; Load mode 0
        bic #DAC12LSEL1, &DAC12_1CTL    ;
        bis #DAC12IR, &DAC12_1CTL       ; Full-Scale=1xVref
        bis #DAC12AMP0, &DAC12_1CTL     ; High speed amplifier output 
        bis #DAC12AMP1, &DAC12_1CTL     ; 
        bis #DAC12AMP2, &DAC12_1CTL     ;
        bic #DAC12DF, &DAC12_1CTL       ; Data format - straight binary 
        bic #DAC12IE, &DAC12_1CTL       ; Interrupt disabled 
        bis #DAC12ENC, &DAC12_1CTL      ; DAC_1 conversion enabled 
 
main:   nop                             ; main program
        mov.w   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
        mov.w   #0x5, &TACCR0           ; Period for up mode
        mov.w   #CCIE, &TACCTL0         ; Enable interrupts on Compare 0
        mov.w   #MC_1|ID_3|TASSEL_2|TACLR, &TACTL
        bis.w   #GIE, SR                ; Enable interrupts (just TACCR0)
 
Mainloop:
        nop                             ; Required only for debugger
        jmp     $                       ; jump to current location '$'                                       
                                        ; (endless loop)
 
TIMER_A0_Interrupt:                     ; adjusted for 128 samples
        clr     R9                      ; clearing the previous filtered mean value
        clr     R13                     ; clearing the previous summing position

        mov     &ADC12MEM0, R14         ; read the value from the ADC
        mov     R14, 0(R4)              ; store the value in the buffer
        add     #2, R4                  ; move the buffer pointer
        inc     R12                     ; increase the position in the buffer

        cmp     #0, R5                  ; check if there are still any non-assigned slots
        jeq     filter                  ; if no non-assigned slots, go to the filter
        dec     R5                      ; decrease the number of non-assigned slots left
        jmp     skip_filter             ; if there are still non-assigned slots, go to the next iteration

filter:
        cmp     #128, R12               ; check if end of buffer is reached
        jeq     anti_overflow           ; if yes, move the pointers back to beginning (anti-overflow mechanism)
        jmp     sum_loop                ; else, go straight to displaying filtered value

anti_overflow:
        mov     R15, R4                 ; reset the buffer pointer
        mov     #0, R12                 ; reset the position in the buffer
        jmp     sum_loop                ; go to displaying filtered value

skip_filter:
        mov     R4, R11                 ; store the buffer pointer
        sub     #2, R11                 ; move the buffer pointer to the current value (reversed the pointer move after saving sample)
        mov     0(R11), &DAC12_1DAT     ; moving unfiltered value to converter DAC_1 (only until the buffer isn't full for the first time)
        jmp     finish                  ; return from interrupt

sum_loop:
        mov     R15, R8                 ; set the buffer pointer to the beginning
        mov     0(R8), R7               ; get the value from the buffer
        rra     R7                      ; right shift x1 (increase or decrease the number of shifts for different amount of samples here)
        rra     R7                      ; right shift x2
        rra     R7                      ; right shift x3
        add     R7, R9                  ; adding the shifted value to sum (to avoid overflow)

        add     #2, R8                  ; move the buffer pointer
        inc     R13                     ; increase the position in the buffer (for summing)

        cmp     #128, R13               ; check if entire buffer was summed
        jeq     display_val             ; if yes, go to the displaying the value
        jmp     sum_loop                ; else, go to the next iteration

display_val:
        rra     R9                      ; right shift the sum x1
        rra     R9                      ; right shift the sum x2
        rra     R9                      ; right shift the sum x3
        rra     R9                      ; right shift the sum x4
        mov     R9, &DAC12_1DAT         ; moving the filtered value to converter DAC_1

finish:
        reti                           ; return from interrupt (finally done with this iteration)
 
        END