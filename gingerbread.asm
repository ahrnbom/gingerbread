; GingerBread is a kind of standard library for Game Boy games written in assembly
; using the RGBDS system. It intends to provide basic functionality that almost 
; every game will need in one form or another. It is meant to be used alongside the
; book... (TODO: link to the book, once available).


; --- Hardware constants ---

; Key status
KEY_START   EQU %10000000
KEY_SELECT  EQU %01000000
KEY_B       EQU %00100000
KEY_A       EQU %00010000
KEY_DOWN    EQU %00001000
KEY_UP      EQU %00000100
KEY_LEFT    EQU %00000010
KEY_RIGHT   EQU %00000001

; Graphics
BG_PALETTE  EQU $FF47

; Memory ranges
TILEDATA_START     equ $8000 ; up to $A000
MAPDATA_START      equ $9800 ; up to $9BFF
MAPDATA1_START     equ $9C00 ; up to $9FFF
RAM_START          equ $C000 ; up to $E000
HRAM_START         equ $F800 ; up to $FFFE
OAMRAM_START       equ $FE00 ; up to $FE9F
AUD3WAVERAM_START  equ $FF30 ; $FF30-$FF3F

DMACODELOC	    equ	$ff80
OAMDATALOC	    equ	RAM_START
OAMDATALOCBANK	equ	OAMDATALOC/$100 
OAMDATALENGTH	equ	$A0

STATF_LYC     EQU  %01000000 ; LYCEQULY Coincidence (Selectable)
STATF_MODE10  EQU  %00100000 ; Mode 10
STATF_MODE01  EQU  %00010000 ; Mode 01 (V-Blank)
STATF_MODE00  EQU  %00001000 ; Mode 00 (H-Blank)
STATF_LYCF    EQU  %00000100 ; Coincidence Flag
STATF_HB      EQU  %00000000 ; H-Blank
STATF_VB      EQU  %00000001 ; V-Blank
STATF_OAM     EQU  %00000010 ; OAM-RAM is used by system
STATF_LCD     EQU  %00000011 ; Both OAM and VRAM used by system
STATF_BUSY    EQU  %00000010 ; When set, VRAM access is unsafe

rSTAT EQU $FF41

; Interrupts
rIF EQU $FF0F
rIE EQU $FFFF

IEF_HILO    EQU  %00010000 ; Transition from High to Low of Pin number P10-P13
IEF_SERIAL  EQU  %00001000 ; Serial I/O transfer end
IEF_TIMER   EQU  %00000100 ; Timer Overflow
IEF_LCDC    EQU  %00000010 ; LCDC (see STAT)
IEF_VBLANK  EQU  %00000001 ; V-Blank

; LCD stuff 
rLCDC EQU $FF40

LCDCF_OFF     EQU  %00000000 ; LCD Control Operation
LCDCF_ON      EQU  %10000000 ; LCD Control Operation
LCDCF_WIN9800 EQU  %00000000 ; Window Tile Map Display Select
LCDCF_WIN9C00 EQU  %01000000 ; Window Tile Map Display Select
LCDCF_WINOFF  EQU  %00000000 ; Window Display
LCDCF_WINON   EQU  %00100000 ; Window Display
LCDCF_BG8800  EQU  %00000000 ; BG & Window Tile Data Select
LCDCF_BG8000  EQU  %00010000 ; BG & Window Tile Data Select
LCDCF_BG9800  EQU  %00000000 ; BG Tile Map Display Select
LCDCF_BG9C00  EQU  %00001000 ; BG Tile Map Display Select
LCDCF_OBJ8    EQU  %00000000 ; OBJ Construction
LCDCF_OBJ16   EQU  %00000100 ; OBJ Construction
LCDCF_OBJOFF  EQU  %00000000 ; OBJ Display
LCDCF_OBJON   EQU  %00000010 ; OBJ Display
LCDCF_BGOFF   EQU  %00000000 ; BG Display
LCDCF_BGON    EQU  %00000001 ; BG Display

; O RLY?
rLY EQU $FF44

rDMA  EQU $FF46

; --- Standard functions ---

SECTION "GingerBreadKeypad",HOME
; Reads current keypad status, stores into A register, where each bit corresponds to one key being pressed or not
; Keys are in the following order: Start - Select - B - A - Down - Up - Left - Right
; The constants KEY_START etc. corresponds to the values obtained here if only that key is pressed.
; The code is copied from the Gameboy Programming Manual, http://www.chrisantonellis.com/files/gameboy/gb-programming-manual.pdf
ReadKeys:
    push bc
    
    ; Read D-pad
	ld a, $20
    ld [$FF00], a 
    ld a, [$FF00]
    ld a, [$FF00]
    cpl
    and %00001111
    ld b, a 
    
    ; Read buttons (Start, Select, B, A)
    ld a, $10
    ld [$FF00], a 
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    ld a, [$FF00]
    cpl
    and %00001111
    
    ; Combine D-pad with buttons, store in B
    swap a 
    or b 
    ld b, a 
    
    ld a, $30
    ld [$FF00], a
    
    ; Return the stored result
    ld a, b
    
    pop bc 
    ret
    
Section "GingerBreadMemory",HOME
WaitForNonBusyLCD: MACRO
    ld  a,[rSTAT]   
    and STATF_BUSY  
    jr  nz,@-4     ; Jumps up 4 bytes in the code (that is, two lines in this case)
ENDM

WaitForNonBusyLCDSafeA: MACRO
    push af 
    WaitForNonBusyLCD
    pop af 
ENDM

; Copies data in a way that is safe to use when reading/writing to/from VRAM while LCD is on (but slower than mCopy)
; HL - memory position of the start of the copying source
; DE - memory position of the start of the copying destination
; BC - the number of bytes to be copied
mCopyVRAM:
    inc b
    inc c
    jr  .skip
.loop:
    di
        ; This "WaitForNonBusyLCD" here, along with the disabled interrupts, makes it safe to read/write to/from VRAM when LCD is on
        ; Essentially, we're waiting for the LCD to be non-busy before reading/writing. If we don't do this, we can
        ; read/write when the LCD is busy which results in corrupted data.
        WaitForNonBusyLCD 
        ld a, [hl+]
        ld [de], a
    ei
    inc de
.skip:
    dec c
    jr  nz, .loop
    dec b
    jr nz, .loop
    ret
    
; Copies data in a way that is NOT safe to use when reading/writing to/from VRAM while LCD is on (but faster than mCopyVRAM)
; HL - memory position of the start of the copying source
; DE - memory position of the start of the copying destination
; BC - the number of bytes to be copied
mCopy:
    inc b
    inc c
    jr  .skip
.loop:
    WaitForNonBusyLCD
    ld a, [hl+]
    ld [de], a
    inc de
.skip:
    dec c
    jr  nz, .loop
    dec b
    jr nz, .loop
    ret
    
; Sets data to a constant value in a way that is safe to use when writing to VRAM while LCD is on (but slower than mSet)
; A  - constant value to set
; HL - memory position of the start of the copying destination
; BC - the number of bytes to be written 
mSetVRAM:
    inc b
    inc c
    jr  .skip
.loop:
    di
        WaitForNonBusyLCDSafeA 
        ld [hl+], a 
    ei
.skip:
    dec c
    jr  nz, .loop
    dec b
    jr nz, .loop
    ret
    
; Sets data to a constant value in a way that is NOT safe to use when writing to VRAM while LCD is on (but faster than mSetVRAM)
; A  - constant value to set
; HL - memory position of the start of the copying destination
; BC - the number of bytes to be written 
mSet:
    inc b
    inc c
    jr  .skip
.loop:
    ld [hl+], a 
.skip:
    dec c
    jr  nz, .loop
    dec b
    jr nz, .loop
    ret
    
    
SECTION "Technical stuff, DMA and stop/start LCD",HOME    
initdma:
	ld	de, DMACODELOC
	ld	hl, dmacode
	ld	bc, dmaend-dmacode
	call mCopyVRAM
	ret
dmacode:
	push	af
	ld	a, OAMDATALOCBANK
	ldh	[rDMA], a
	ld	a, $28
dma_wait:
	dec	a
	jr	nz, dma_wait
	pop	af
	reti
dmaend:
    nop 
    
StopLCD:
    ld a, [rLCDC]
    rlca  
    ret nc ; In this case, the LCD is already off

.wait:
    ld a,[rLY]
    cp 145
    jr nz, .wait

    ld  a, [rLCDC]
    res 7, a 
    ld  [rLCDC], a

    ret

StartLCD:
    ; Turns on LCD with default settings 
    ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
	ld	[rLCDC], a
    ret     