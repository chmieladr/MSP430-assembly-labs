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

init:   MOV     #SFE(CSTACK), SP        ; set up stack
        ; setting the necessary bits to make the needed converters work
        BIS.B #00010000b, &P1DIR ; set P1.4 as out (DAC_P2)
        BIS.B #10000000b, &P5DIR ; set P5.7 as out (DAC_P2)
        BIC.B #00010000b, &P1OUT ; clear bit P1.4 (DAC_P2)
        BIC.B #10000000b, &P5OUT ; clear bit P5.7 (DAC_P2)

        ; initialisation of the starting point
        MOV #010000000000b, R5 ; initialisation of x
        MOV #0, R4 ; initialisation of y
        MOV #0, R6 ; flag for drawing mode - inititally drawing the vertical line

        ; rest of the setup below copied from template
        ;---------- Basic Clock Module Initialisation --------------------------------------
        ; - switch from DCO to XT2
        ; - MCLK & SMCLK supplied from XT2, ACLK = n/a
        ; - the DCO is left runing
        bis.b #OSCOFF,SR ;turn OFF osc.1
        bic.b #XT2OFF,BCSCTL1 ;turn ON osc.2
BCM0    bic.b #OFIFG,&IFG1 ;clear OFIFG
        mov #0FFFFh,R15 ;delay (waiting for oscilator start)
BCM1    dec R15 ;delay
        ;jnz BCM1 ;delay -> commented out as it was ocasionally leading to infinite loop
        bit.b #OFIFG,&IFG1 ;test OFIFG
        jnz BCM0 ;repeat test if needed
        ;MCLK
        bic.b #040h,&BCSCTL2 ;slelect XT2CLK as source
        bis.b #080h,&BCSCTL2 ;
        bic.b #030h,&BCSCTL2 ;MCLK=source/1 (8MHz)
        ;SMCLK
        bis.b #SELS,&BCSCTL2 ;slelect XT2CLK as source
        bic.b #006h,&BCSCTL2 ;SMCLK=source/1 (8MHz)
        ;---------------------------------------------------------------------------------

        ;..................................................................................... ;DAC_0 initialisation 
        bis.w #REFON+REF2_5V,&ADC12CTL0 ;Reference generator ON, VRef+=2.5V
        bic #DAC12SREF0,&DAC12_0CTL ;set Vref=VREF+
        bic #DAC12SREF1,&DAC12_0CTL ;
        bic #DAC12RES,&DAC12_0CTL ;12-bit resolution
        bic #DAC12LSEL0,&DAC12_0CTL ;Load mode 0
        bic #DAC12LSEL1,&DAC12_0CTL ;
        bis #DAC12IR,&DAC12_0CTL ;Full-Scale=1xVref
        bis #DAC12AMP0,&DAC12_0CTL ;High speed amplifier output 
        bis #DAC12AMP1,&DAC12_0CTL ; 
        bis #DAC12AMP2,&DAC12_0CTL ;
        bic #DAC12DF,&DAC12_0CTL ;Data format - straight binary 
        bic #DAC12IE,&DAC12_0CTL ;Interrupt disabled 
        bis #DAC12ENC,&DAC12_0CTL ;DAC_0 conversion enabled 
        ;.................................................................................

        ;..................................................................................... ;DAC_1 initialisation 
        bis.w #REFON+REF2_5V,&ADC12CTL0 ;Reference generator ON, VRef+=2.5V
        bic #DAC12SREF0,&DAC12_1CTL ;set Vref=VREF+
        bic #DAC12SREF1,&DAC12_1CTL ;
        bic #DAC12RES,&DAC12_1CTL ;12-bit resolution
        bic #DAC12LSEL0,&DAC12_1CTL ;Load mode 0
        bic #DAC12LSEL1,&DAC12_1CTL ;
        bis #DAC12IR,&DAC12_1CTL ;Full-Scale=1xVref
        bis #DAC12AMP0,&DAC12_1CTL ;High speed amplifier output 
        bis #DAC12AMP1,&DAC12_1CTL ; 
        bis #DAC12AMP2,&DAC12_1CTL ;
        bic #DAC12DF,&DAC12_1CTL ;Data format - straight binary 
        bic #DAC12IE,&DAC12_1CTL ;Interrupt disabled 
        bis #DAC12ENC,&DAC12_1CTL ;DAC_1 conversion enabled 
        ;...............................................................................��..
 
main:   NOP                             ; main program
        MOV.B   #255, P2DIR             ; set all pins from port 2 as outputs
        MOV.B   #0, P2OUT               ; set port 2 to low
        MOV.W   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
        mov.w   #0x5, &TACCR0           ; Period for up mode
        mov.w   #CCIE, &TACCTL0         ; Enable interrupts on Compare 0
        mov.w   #MC_1|ID_3|TASSEL_2|TACLR, &TACTL
        bis.w   #GIE, SR                ; Enable interrupts (just TACCR0)

Mainloop:
        nop                             ; Required only for debugger
        JMP $                           ; jump to current location '$'                                       
                                        ; (endless loop)

; 'T' letter
TIMER_A0_Interrupt:
        CMP #1, R6                      ; check if the vertical line is done
        JNZ draw_vertical_line          ; if not, go to draw_vertical_line
        JMP draw_horizontal_line        ; if done, go to draw_horizontal_line
draw_vertical_line:
        ADD #1, R4                      ; i++ on y-axis
        CMP #255, R4                    ; until we reach 255 on y-axis
        JNZ output                      ; if not reached, go straight to output
        MOV #0, R5                      ; if reached, changing the x-axis value to 0
        MOV #1, R6                      ; and set the flag to indicate that the vertical line is done
        JMP output                      ; go to output
draw_horizontal_line:
        ADD #16, R5                     ; i += 16 on x-axis
        CMP #100000000000b, R5          ; until we reach 255 on x-axis
        JNZ output                      ; if not reached, go straight to output
        MOV #010000000000b, R5          ; x = start point (resetting the values if reached)
        MOV #0, R4                      ; y = 0
        MOV #0, R6                      ; back to drawing the vertical line again
output:
        MOV    R5, &DAC12_1DAT          ; moving the value to converter responsible for x-axis
        MOV.B  R4, &P2OUT               ; moving the value to converter responsible for y-axis
        RETI

        END