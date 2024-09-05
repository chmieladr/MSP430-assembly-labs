# MSP430
Repository that contains my entire code written in *Assembly MSP430*. Tested on *MSP430F169* microcontroller. **Might contain mistakes!**

## Sources
* [Microprocessor Technology Blog by Kamil Możdżyński](https://monjino.atlassian.net/wiki/spaces/TM/overview?homepageId=1077051583) -> _not publicly available anymore_
* Documentary _PDF_ files available in `docs/documentation` directory:
    * `Blocks_scheme.pdf`
    * `msp430f169.pdf`
    * `slau049f.pdf`

> **Note!** If you just want to have a look at the code, it is recommended to use
  **_MSP430 Assembly_** extention in _Visual Studio Code_ that will (at least partially) highlight the code for you! 

## Main files (src)
Here's a quick recap of what each project file contains. 
> It is highly recommended to have a look at all comments since they might significantly help you with understanding this entire messy code.

#### Lab1.s
- program that counts the sum of weights assigned to the currently pressed buttons
- uses P4.0-P4.3 buttons where each button exclusively has one of the corresponding weights: 1, 2, 3, 4
- lets you print a number in range 0-10 on the output 7-seg display connected to P2

#### Lab2.s
- program that lets you change the currently displayed number using the encoder
- the available numbers are within the range 6-12, shown on the 7-seg display connected to P2

#### sin_limit.s
- program that is able to generate the signal based on one of four available forms:
  - sinus
  - triangle
  - rectangle
  - saw
- sinus can be limited from above and below based on the values initialised in R7 and R9 registers
- more info about the given exercise here: `docs/exercises_*/DAC_sinus_limit.pdf`

#### xy.s
- program that uses two converters to generate simple signal based on y = x function
- more info about the given exercise here: `docs/exercises_*/DACs_XY.pdf`

#### t_letter.s
- program that yet again uses two converters to generate signal that will look like 'T' letter on the oscilloscope's display
- more info about the given exercise here: `docs/exercises_*/DACs_XY.pdf`

#### timer.s
- program that implements a simple timer
- features three buttons with START, STOP and RESET functionalities
- uses 7-seg display on P2 port to show the result
- more info about the given exercise here: `docs/exercises_*/Timer_A_NBC2BCD_2.pdf`

#### reaction.s
- program that lets you measure your reaction time with precision of 0.01 seconds
- features two buttons with INIT and STOP functionalities
- after the initialization, the program waits from 1 to 6 seconds
- the measure starts after displaying '00' on the 7-seg display connected to P2 port
- your task is to click STOP as quickly as possible after the '00' is shown
- the result is shown on the 7-seg display (as long as your reaction was faster than an entire second)
- more info about the given exercise here: `docs/exercises_*/reaction.pdf`

#### adc.s
- program that configurates ADC converter
- copies the result and passes it to DAC converter along with displaying it on the 7-seg display
- more info about the given exercise here: `docs/exercises_*/ADC_delay_DAC.pdf`

#### mean_filter.s
- program that implements a moving average filter for the signals
- averaging based on 128 most recent probes
- more info about the given exercise here: `docs/exercises_*/filter_mean.pdf`

#### exp_filter.s
- program that implements exponential filter for the signals
- more info about the given exercise here: `docs/exercises_*/filter_2.pdf`

### Utilities
This section contains other useful programmes that helped with preparing the code for files visible above.

#### triangle.py
- Helped with generating triangle form displayed later in oscilloscope used inside of `sin_limit.s` file.
- Written in Python