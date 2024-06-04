#include "msp430.h"                     ; #define controlled include file
 
        NAME    main                    ; module name
 
        PUBLIC  main                    ; make the main label vissible
                                        ; outside this module
        ORG     0FFECh
        DC16    TIMER_A0_Interrupt
        ORG     0FFE8h                  
        DC16    PORT1_isr               ; set PORT1 Interrupt vector
        ORG     0FFFEh
        DC16    init                    ; set reset vector to 'init' label
 
        RSEG    CSTACK                  ; pre-declaration of segment
        RSEG    CODE                    ; place program in 'CODE' segment
 
waveform:                               ; quantified sinus waveform as an array
        DW      2000, 2126, 2251, 2375, 2497, 2618, 2736, 2852, 2964, 3072, 3176, 3275, 3369, 3458, 3541, 3618, 3689, 3753, 3810, 3860, 3902, 3937, 3965, 3984, 3996, 4000, 3996, 3984, 3965, 3937, 3902, 3860, 3810, 3753, 3689, 3618, 3541, 3458, 3369, 3275, 3176, 3072, 2964, 2852, 2736, 2618, 2497, 2375, 2251, 2126, 2000, 1874, 1749, 1625, 1503, 1382, 1264, 1148, 1036, 928, 824, 725, 631, 542, 459, 382, 311, 247, 190, 140, 98, 63, 35, 16, 4, 0, 4, 16, 35, 63, 98, 140, 190, 247, 311, 382, 459, 542, 631, 725, 824, 928, 1036, 1148, 1264, 1382, 1503, 1625, 1749, 1874
 
triangleform:                           ; quantified triangleform values generated using triangle.py
        DW      0, 80, 160, 240, 320, 400, 480, 560, 640, 720, 800, 880, 960, 1040, 1120, 1200, 1280, 1360, 1440, 1520, 1600, 1680, 1760, 1840, 1920, 2000, 2080, 2160, 2240, 2320, 2400, 2480, 2560, 2640, 2720, 2800, 2880, 2960, 2960, 2880, 2800, 2720, 2640, 2560, 2480, 2400, 2320, 2240, 2160, 2080, 2000, 1920, 1840, 1760, 1680, 1600, 1520, 1440, 1360, 1280, 1200, 1120, 1040, 960, 880, 800, 720, 640, 560, 480, 400, 320, 240, 160, 80, 0, 80, 160, 240, 320, 400, 480, 560, 640, 720, 800, 880, 960, 1040, 1120, 1200, 1280, 1360, 1440, 1520, 1600, 1680, 1760, 1840, 1920, 2000, 2080, 2160, 2240, 2320, 2400, 2480, 2560, 2640, 2720, 2800, 2880, 2960, 2960, 2880, 2800, 2720, 2640, 2560, 2480, 2400, 2320, 2240, 2160, 2080, 2000, 1920, 1840, 1760, 1680, 1600, 1520, 1440, 1360, 1280, 1200, 1120, 1040, 960, 880, 800, 720, 640, 560, 480, 400, 320, 240, 160, 80

rectform:                               ; to be possibly replaced with proper XOR in the future
        DW      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000, 3000
 
init:   mov     #SFE(CSTACK), SP        ; set up stack
        mov.b   #255, P2DIR             ; set all pins from port 2 as outputs
        mov.b   #0, P2OUT               ; set port 2 to low

; Limits for sinus waveform
        mov     #3500, R9               ; set the upper limit
        mov     #500, R7                ; set the lower limit
        mov     #0, R4
 
main:   nop                             ; main program
        mov.w   #WDTPW+WDTHOLD, &WDTCTL ; Stop watchdog timer
        mov.b   #1111b, P1IE            ; P1.3 interrupt enabled
        mov.b   #1111b, P1IES           ; P1.3 Hi/lo edge
        bic.b   #1111b, P1IFG           ; IFG cleared
        bis.w   #GIE, SR                ; Enable interrupts (just TACCR0)
 
SetupADC12:  
        mov.w   #REF2_5V+REFON, &ADC12CTL0 ; Internal 2.5V ref on
 
SetupDAC120: 
        mov.w   #DAC12IR+DAC12AMP_5+DAC12ENC, &DAC12_1CTL  ; Int ref gain 1
        mov.w   #0h, &DAC12_1DAT
SetupTimerA0                             
        mov.w   #0x10, &TACCR0          ; Period for up mode
        mov.w   #CCIE, &TACCTL0         ; Enable interrupts on Compare 0
 
        ; Set up Timer A. Up mode, divide clock by 8, clock from SMCLK, clear TAR
        mov.w   #MC_1|ID_3|TASSEL_2|TACLR, &TACTL
        bis.w   #GIE, SR                ; Enable interrupts (just TACCR0)
 
Mainloop:
        nop                             ; Required only for debugger
        jmp $                           ; jump to current location '$'                                       
                                        ; (endless loop)
 
PORT1_isr:
        mov.b   P4IN, R10
        mov     #0, R11                 ; clearing the registers after each toggle
        mov     #0, R12
        mov     #0, R13
        mov     #0, R14
        clr     R4
        mov.b   #00001000b, R14         ; RECT state
        and.b   R10, R14
        mov.b   #00000100b, R13         ; TRIAN state      
        and.b   R10, R13
        mov.b   #00000010b, R12         ; SAW state
        and.b   R10, R12
        mov.b   #00000001b, R11         ; SINUS state
        and.b   R10, R11
        bic.b   #1111b, P1IFG           ; confirmation of interrupt handling
        reti                            ; Return from Interrupt Service Routine
 
TIMER_A0_Interrupt:
        cmp  #00001000b, R14            ; hopping into the right state based on result above
        jnz  rect
        cmp  #00000100b, R13
        jnz  trian
        cmp  #00000010b, R12
        jnz  saw
        cmp  #00000001b, R11
        jnz  sinus
 
sinus:
        add  #1, R4                     ; i += 1
        cmp  #200, R4                   ; i < 200
        jnz  output_sin        
        mov  #0, R4                     ; i = 0
output_sin:
        mov  #waveform, R5
        add  R4, R5                     ; moving the index in array to get t[R4] value
        mov  @R5, R15
        cmp  R9, R15                    ; checking for upper limit
        jhs  upper_limit
lower_check:
        cmp  R7, R15                    ; checking for lower limit
        jlo  lower_limit
        jmp  final_output
upper_limit:
        mov  R9, R15                    ; replacing the value with the limit if it's too high
        jmp  lower_check
lower_limit:
        mov  R7, R15                    ; replacing the value with the limit if it's too low
final_output:
        mov  R15, &DAC12_1DAT           ; DAC = waveform[i]
        reti
 
saw:
        add  #1, R4                     ; i += 1
        cmp  #200, R4                   ; i < 200
        jnz  output_saw       
        mov  #0, R4                     ; i = 0
output_saw:
        add  #100, R15                  ; based on overloading the value
        mov  R15, &DAC12_1DAT
        reti
 
trian:
        add  #1, R4                     ; i += 1
        cmp  #150, R4                   ; i < 150
        jnz  output_troj        
        mov  #0, R4                     ; i = 0
output_trian:
        mov  #triangleform, R5           
        add  R4, R5                      
        mov  @R5, &DAC12_1DAT           ; DAC = triangleform[i]
        reti
 
rect:
        add  #1, R4                     ; i += 1
        cmp  #160, R4                   ; i < 160
        jnz  output_prost        
        mov  #0, R4                     ; i = 0
output_rect:
        mov  #rectform, R5           
        add  R4, R5                      
        mov  @R5, &DAC12_1DAT           ; DAC = rectform[i]
        reti

        END