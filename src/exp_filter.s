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
 
init:   mov     #SFE(CSTACK), SP        ; set up stack
        mov.b   #255, P2DIR             ; set all pins from port 2 as outputs
        mov.b   #0, P2OUT               ; set port 2 to low
        mov     #011111111111b, R7      ; first y_n-1 initialization
 
; Alpha initialization
        mov     #0, R4                  ; possible values: {0: 0, 1: 1/4, 2: 1/2, 3: 3/4, 4: 1}
 
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
        mov.w   #0x160, &TACCR0         ; Period for up mode
        mov.w   #CCIE, &TACCTL0         ; Enable interrupts on Compare 0
        mov.w   #MC_1|ID_3|TASSEL_2|TACLR, &TACTL
        bis.w   #GIE, SR                ; Enable interrupts (just TACCR0)
 
Mainloop:
        nop                             ; Required only for debugger
        jmp     $                       ; jump to current location '$'                                       
                                        ; (endless loop)
 
TIMER_A0_Interrupt:                     ; R6 = y_n-1 | R5 = x_n | R4 = alpha 
        mov     R7, R6                  ; copy previous value to R6
        mov     &ADC12MEM0, R5          ; read ADC value
        clr     R7                      ; clear previous result
        cmp     #0, R4                  ; if alpha == 0
        jeq     alpha0                  ; jump to alpha0
        cmp     #1, R4                  ; if alpha == 1/4
        jeq     alpha1                  ; jump to alpha1
        cmp     #2, R4                  ; if alpha == 1/2
        jeq     alpha2                  ; jump to alpha2
        cmp     #3, R4                  ; if alpha == 3/4
        jeq     alpha3                  ; jump to alpha3
        cmp     #4, R4                  ; if alpha == 1
        jeq     alpha4                  ; jump to alpha4
        jmp     finish                  ; jump to finish if alpha invalid

alpha0:                                 ; alpha = 0 (copy previous output)
        mov     R6, R7                  ; y(n) = y_n-1
        jmp     finish                  ; jump to finish

alpha1:                                 ; alpha = 1/4
        mov     R5, R8                  ; a = x_n
        rra     R8                      ; a = x_n / 2
        rra     R8                      ; a = x_n / 4
        mov     R6, R9                  ; b = y_n-1
        rra     R9                      ; b = y_n-1 / 2
        rra     R9                      ; b = y_n-1 / 4
        add     R8, R7                  ; y(n) = a | y(n) = x_n / 4
        add     R9, R7                  ; y(n) = a + b  | y(n) = x_n / 4 + y_n-1 / 4
        add     R9, R7                  ; y(n) = a + 2b | y(n) = x_n / 4 + y_n-1 * 2 / 4
        add     R9, R7                  ; y(n) = a + 3b | y(n) = x_n / 4 + y_n-1 * 3 / 4
        jmp     finish                  ; jump to finish

alpha2:                                 ; alpha = 1/2
        mov     R5, R8                  ; a = x_n
        rra     R8                      ; a = x_n / 2
        mov     R6, R9                  ; b = y_n-1
        rra     R9                      ; b = y_n-1 / 2
        add     R8, R7                  ; y(n) = a     | y(n) = x_n / 2
        add     R9, R7                  ; y(n) = a + b | y(n) = x_n / 2 + y_n-1 / 2
        jmp     finish                  ; jump to finish

alpha3:                                 ; alpha = 3/4
        mov     R5, R8                  ; a = x_n
        rra     R8                      ; a = x_n / 2
        rra     R8                      ; a = x_n / 4
        mov     R6, R9                  ; b = y_n-1
        rra     R9                      ; b = y_n-1 / 2
        rra     R9                      ; b = y_n-1 / 4
        add     R8, R7                  ; y(n) = a      | y(n) = x_n / 4
        add     R8, R7                  ; y(n) = 2a     | y(n) = x_n * 2 / 4
        add     R8, R7                  ; y(n) = 3a     | y(n) = x_n * 3 / 4
        add     R9, R7                  ; y(n) = 3a + b | y(n) = x_n * 3 / 4 + y_n-1 / 4
        jmp     finish                  ; jump to finish

alpha4:                                 ; alpha = 1 (no change)
        mov     R5, R7                  ; y(n) = x_n
        jmp     finish                  ; jump to finish

finish:
        mov     R7, &DAC12_1DAT         ; move result to display register
        reti                            ; return from interrupt
 
        END