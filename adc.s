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
        ; DAC_2 (P2) config
        BIS.B #00010000b, &P1DIR ; set P1.4 as out
        BIS.B #10000000b, &P5DIR ; set P5.7 as out
        BIC.B #00010000b, &P1OUT ; clear bit P1.4
        BIC.B #10000000b, &P5OUT ; clear bit P5.7
        MOV.B #255, P2DIR        ; set all pins from port 2 as outputs
        MOV.B #0, P2OUT          ; set port 2 to low

        ; ADC config (based on documentation)
        BIS.W #0000100011110000b, &ADC12CTL0
        ; SHT0 = 1000b (256 cycles) | MSC = 1 | REF2_5V = 1 | REFON = 1 | ADC12ON = 1
        BIS.W #0000001000000010b, &ADC12CTL1
        ; SHP = 1 | CONSEQ2 = 1 -> A1 goes to MEM0
        BIS.B #00000001b, &ADC12MCTL0 ; set input channel as A1
        BIS.B #10b, &P6SEL ; set P6.1 as analog input
        BIS.W #11b, &ADC12CTL0 ; has to be at the end
        ; ENC = 1 | ADC12SC = 1 -> enables and starts conversion
 
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
        ;...............................................................................……..
 
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
        ;...............................................................................……..
 
main:   NOP                             ; main program
        MOV.W   #WDTPW+WDTHOLD,&WDTCTL  ; Stop watchdog timer
        mov.w   #0x5,&TACCR0            ; Period for up mode
        mov.w   #CCIE,&TACCTL0          ; Enable interrupts on Compare 0
        mov.w   #MC_1|ID_3|TASSEL_2|TACLR,&TACTL
        bis.w   #GIE,SR                 ; Enable interrupts (just TACCR0)
 
Mainloop:
        nop                             ; Required only for debugger
        JMP $                           ; jump to current location '$'                                       
                                        ; (endless loop)
 
TIMER_A0_Interrupt:
        MOV.W  &ADC12MEM0, R5           ; moving the value from ADC to R5
        MOV    R5, &DAC12_1DAT          ; moving that value to converter DAC_1 
        MOV.B  R5, &P2OUT               ; moving that value to converter DAC_2
        RETI
 
        END