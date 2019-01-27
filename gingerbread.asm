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

; Graphics palettes (monochrome)
BG_PALETTE       EQU $FF47
SPRITE_PALETTE_1 EQU $FF48
SPRITE_PALETTE_2 EQU $FF49

; Scrolling: Set these to nonzero values to scroll the screen across the 256x256 rendering surface
SCROLL_X         EQU $FF43
SCROLL_Y         EQU $FF42
; They see me scrollin'... They hatin'...

; Memory ranges
TILEDATA_START     equ $8000 ; up to $A000
MAPDATA_START      equ $9800 ; up to $9BFF
MAPDATA1_START     equ $9C00 ; up to $9FFF

RAM_START          equ $C000 ; up to $E000, only write to data after USER_RAM_START as GingerBread uses some RAM before this for sprites etc.
SPRITES_START      equ $C000 ; up to $C0A0
USER_RAM_START     equ $C100 ; up to $E000

HRAM_START         equ $F800 ; up to $FFFE
OAMRAM_START       equ $FE00 ; up to $FE9F
AUD3WAVERAM_START  equ $FF30 ; $FF30-$FF3F

DMACODE_START   equ $FF80
SPRITES_LENGTH  equ $A0

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
IEF_LCDC    EQU  %00000010 ; LCDC
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

; Sound stuff 
SOUND_VOLUME    EQU $FF24
SOUND_OUTPUTS   EQU $FF25
SOUND_ONOFF     EQU $FF26

; Channel 1 (square with sweep and enevelope effects)
SOUND_CH1_START     EQU $FF10 ; bit 7: unused, bits 6-4: sweep time, bit 3: sweep frequency increase/decrease, bits 2-0: number of sweep shifts
SOUND_CH1_LENGTH    EQU $FF11 ; bits 7-6: wave duty, bits 5-0: length of sound data 
SOUND_CH1_ENVELOPE  EQU $FF12 ; bits 7-4: start value for envelope, bit 3: envelope decrease/increase, bits 2-0: number of envelope sweeps
SOUND_CH1_LOWFREQ   EQU $FF13 ; bits 7-0: lower 8 bits of the sound frequency 
SOUND_CH1_HIGHFREQ  EQU $FF14 ; bit 7: restart channel, bit 6: use length, bits 5-3: unused, bits 2-0: highest 3 bits of frequency

; Channel 2 (square with enevelope effect, with no sweep effect)
SOUND_CH2_START     EQU $FF15 ; Not used but you can write zeroes here 
SOUND_CH2_LENGTH    EQU $FF16 ; bits 7-6: wave duty, bits 5-0: length of sound data 
SOUND_CH2_ENVELOPE  EQU $FF17 ; bits 7-4: start value for envelope, bit 3: envelope decrease/increase, bits 2-0: number of envelope sweeps
SOUND_CH2_LOWFREQ   EQU $FF18 ; bits 7-0: lower 8 bits of the sound frequency 
SOUND_CH2_HIGHFREQ  EQU $FF19 ; bit 7: restart channel, bit 6: use length, bits 5-3: unused, bits 2-0: highest 3 bits of frequency

; Channel 3 (custom wave)
SOUND_CH3_START     EQU $FF1A ; bit 7: on/off, bits 6-0: unused 
SOUND_CH3_LENGTH    EQU $FF1B ; bits 7-0: length of sound 
SOUND_CH3_VOLUME    EQU $FF1C ; bits 6-5: audio volume (%00 is mute, %01 is loudest, %10 is pretty quiet and %11 is very quiet)
SOUND_CH3_LOWFREQ   EQU $FF1D ; bits 7-0: lower 8 bits of the sound frequency
SOUND_CH3_HIGHFREQ  EQU $FF1E ; bit 7: restart channel, bit 6: use length, bits 5-3: unused, bits 2-0: highest 3 bits of frequency

; Channel 4 (noise)
SOUND_CH4_START     EQU $FF1F ; Not used but you can write zeroes here 
SOUND_CH4_LENGTH    EQU $FF20 ; bits 5-0: length of sound 
SOUND_CH4_ENVELOPE  EQU $FF21 ; bits 7-4: start value for envelope, bit 3: envelope decrease/increase, bits 2-0: number of envelope sweeps
SOUND_CH4_POLY      EQU $FF22 ; bits 7-4: polynomial counter, bit 3: number of steps (15 or 7), bits 2-0: ratio of frequency division (%000 gives highest frequency, %111 the lowest)
SOUND_CH4_OPTIONS   EQU $FF23 ; bit 7: restart channel, bit 6: use length

; Wave table for Channel 3 
SOUND_WAVE_TABLE_START EQU $FF30
SOUND_WAVE_TABLE_STOP  EQU $FF3F

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

Section "GingerBreadSound",HOME 
; Enables audio on all channels, at maximum output volume. 
; Overwrites AF 
EnableAudio:
    ld a, %11111111
    ld [SOUND_VOLUME],  a ; Max out the audio volume 
    ld [SOUND_OUTPUTS], a ; Output all channels to both left/right speakers (when using headphones)
    ld [SOUND_ONOFF],   a ; Turn audio on 
    
    ret 

; Use this if your game doesn't use audio, to save some battery life 
; Overwrites AF     
DisableAudio: 
    xor a 
    ld [SOUND_VOLUME],  a ; Turn off the audio volume 
    ld [SOUND_OUTPUTS], a ; Output no channels to no left/right speakers (when using headphones)
    ld [SOUND_ONOFF],   a ; Turn audio off 
    
    ret 
    
; HL should point to a table which first contains a DW with either SOUND_CH1_START, SOUND_CH2_START, SOUND_CH3_START or SOUND_CH4_START
; followed by five values to be written to those addresses (see comments by the definitions of those constants)
; Overwrites AF and HL 
PlaySoundHL: 
    push de 
    
    ; Read channel start into DE 
    ld a, [hl+]
    ld e, a 
    ld a, [hl+]
    ld d, a 
    
    ; Read data from table and feed into the channel start 
    ld a, [hl+] 
    ld [de], a
    inc de 
    
    ld a, [hl+]
    ld [de], a 
    inc de
    
    ld a, [hl+]
    ld [de], a 
    inc de 
    
    ld a, [hl+]
    ld [de], a
    inc de 

    ld a, [hl]
    ld [de], a 
    
    pop de 
    ret 
    
Section "GingerBreadMemory",HOME
WaitForNonBusyLCD: MACRO
    ld  a,[rSTAT]   
    and STATF_BUSY  
    jr  nz,@-4     ; Jumps up 4 bytes in the code (two lines in this case)
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
    

; --- Boot process and interrupts ---
; Feel free to change interrupts if your game should use them

; Interrupts
SECTION	"vblank interrupt",HOME[$0040]
    jp	DMACODE_START ; sprites should be updated on every vblank
SECTION	"LCDC interrupt",HOME[$0048]
    reti
SECTION	"Timer overflow interrupt",HOME[$0050]
    reti
SECTION	"Serial interrupt",HOME[$0058]
    reti
SECTION	"p1234 interrupt",HOME[$0060]
    reti

; These are the first lines the boot loader will run. Make sure you have defined a "begin" label in your game code!
SECTION	"GingerBread start",HOME[$0100]
    nop
    jp	begin

    
SECTION "GingerBread Technical stuff, DMA and stop/start LCD",HOME    
initdma:
	ld	de, DMACODE_START
	ld	hl, dmacode
	ld	bc, dmaend-dmacode
	call mCopyVRAM
	ret
dmacode:
	push	af
	ld	a, SPRITES_START/$100 ; When doing DMA, the address is given as an 8-bit number, to be multiplied by $100
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
    ; Turns on LCD with reasonable settings (with 8x16 sprites!) 
    ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJON
	ld	[rLCDC], a
    ret     