
# Z8800_Super8_testboard

Test board for MCU Z08800020 (Super8 / Z8) from Zilog.

More details : plz refer my blog [https://vita-brevis.hatenablog.com/archive/category/Z8800%20%28Super8%29].

<img width="1600" height="1315" alt="PXL_20260621_173558486~2+1" src="https://github.com/user-attachments/assets/e0c5c913-6030-4138-8e32-b3851febaa82" />

## bugs

**These bugs are currently NOT fixed yet**. Be careful for using assets.

- No need for implementing pull-up register arrays RN2. Instead of this, you HAVE TO ADD pull-down register to A13-A15
- Port 2 signals are wrongly connected to DAC08. The bits order are backwards. B0 SHOULD be connected to P2_7, B7 SHOULD be connected to P2_0.
- The pin assigns of DTR and RxD on the D-sub connector are backwards.
- GAL logic comment SHOULD BE FIXED as : #RAM_WE = #DS # R/#W, #RAM_OE = #DS # !R/#W

These are not bugs but recommended to be fixed:

- Add #DM (P3_5) signal to GAL input. #DM is a signal to distinguish between access to the program memory and to the data memory.

## Spec

- ROM 27256 (32kB)
- RAM 62256 (32kB)
- Address decoder GAL16V8B
- 1 LED port (LED x8)
- 1 DAC port (DAC08 ... to accomplish the sine wave generation described on Super8 Application Note)
- 1 UART port (RS-232)

## Assets

### Schematics

KiCad v9

[KiCad_Z8800](KiCad_Z8800/KiCad_Z8800_sch.pdf)

### PCB design

KiCad v9

### GAL JEDEC file

WinCupl

### Program

Macro Asseembler

