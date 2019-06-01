; GingerBread is a kind of standard library for Game Boy games written in assembly
; using the RGBDS system. It intends to provide basic functionality that almost 
; every game will need in one form or another. It is meant to be used alongside the
; book... (TODO: link to the book, once available).

; --- ROM Header ---

; Before importing gingerbread.asm, you can specify the following options to affect the game header
IF !DEF(GAME_NAME)    
GAME_NAME EQUS "GINGERBREAD"
ENDC

IF !DEF(GBC_SUPPORT)
H_GBC_CODE EQU $0
ELSE
H_GBC_CODE EQU $80
ENDC

IF !DEF(SGB_SUPPORT)
H_SGB_CODE EQU $0
ELSE
H_SGB_CODE EQU $3
ENDC

IF !DEF(ROM_SIZE)
ROM_SIZE EQU 0
ENDC

IF !DEF(RAM_SIZE)
RAM_SIZE EQU 1
ENDC
    
SECTION "header",ROM0[$0104]

    ; "Nintendo" logo. If this is modified, the game won't start on a real Gameboy.
    DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
    DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
    DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

    ; The header, specifying ROM details. 
    DB {GAME_NAME}          ; $134 - Title of the game, in uppercase ASCII. Should be exactly 15 characters (padded with 0s if necessary)
REPT 15-STRLEN({GAME_NAME})
    DB 0
ENDR    
    DB 	H_GBC_CODE          ; $143 - GBC functionality (0 for no, $80 for "black cart" and $C0 for GBC only)
    DB 	0,0                 ; $144 - Licensee code (not important)
    DB 	H_SGB_CODE          ; $146 - SGB Support indicator (0 means no support, 3 means there is SGB support in the game)
    DB 	$1B                 ; $147 - Cart type ($1B means MBC5 with RAM and battery save)
    DB 	ROM_SIZE            ; $148 - ROM Size, 0 means 32 kB, 1 means 64 kB and so on up to 2 MB
    DB	RAM_SIZE            ; $149 - RAM Size, 0 means no RAM, 1 means 2 kB, 2 -> 8 kB, 3 -> 32 kB, 4 -> 128 kB
    DB 	1                   ; $14a - Destination code (0 means Japan, 1 mean non-Japan, doesn't matter)
    DB 	$33                 ; $14b - Old licensee code, needs to be $33 for SGB to work
    DB 	0                   ; $14c - Mask ROM version
    DB 	0                   ; $14d - Complement check (important, RGBDS takes care of this)
    DW 	0                   ; $14e - Checksum (not important, RGBDS takes care of this)


; --- Hardware constants ---

; General 
ROM_BANK_SWITCH     EQU $2000
SAVEDATA            EQU $0000
MBC5_RAMB           EQU $4000

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
TILEDATA_START              EQU $8000 ; up to $97FF
BACKGROUND_MAPDATA_START    EQU $9800 ; up to $9BFF
WINDOW_MAPDATA_START        EQU $9C00 ; up to $9FFF

SAVEDATA_START     EQU $A000 ; up to $BFFF

RAM_START          EQU $C000 ; up to $E000, only write to data after USER_RAM_START as GingerBread uses some RAM before this for sprites etc.
SPRITES_START      EQU $C000 ; up to $C0A0
USER_RAM_START     EQU $C100 ; up to $E000

HRAM_START         EQU $F800 ; up to $FFFE
OAMRAM_START       EQU $FE00 ; up to $FE9F
AUD3WAVERAM_START  EQU $FF30 ; $FF30-$FF3F

DMACODE_START   EQU $FF80
SPRITES_LENGTH  EQU $A0

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

; --- GingerBread RAM variables ---
; GingerBread writes a few variables in RAM between $C000 and $C100. Let your own RAM usage start at $C100 to make sure none of your code messes with GingerBread
SECTION "GingerBread RAM variables",WRAM0[$C000]
RUNNING_ON_SGB: DS 1 
RUNNING_ON_GBC: DS 1 


; --- Standard functions ---

SECTION "GingerBreadKeypad",ROM0
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

Section "GingerBreadSound",ROM0 
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
    
Section "GingerBreadMemory",ROM0
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
    

; --- Text and number display ---

; Draws text until a specific end character appears, using X/Y coordinates, which can be a bit slower than RenderTextToEndByPosition
; B - tile number of end character
; C - zero if drawn to background, non-zero if drawn to window 
; D - X position
; E - Y position 
; HL - address to start of the text to write, make sure it contains the end character somewhere 
RenderTextToEnd:
    ; Convert position coordinates to position number  
    push hl 
    
    xor a 
    ld h, a
    ld l, a 
    call XYtoPosition
    
    ; Put position number at DE and then restore HL 
    ld d, h 
    ld e, l  
    pop hl 
    
    call RenderTextToEndByPosition
    ret     

; Draws text until a specific end character appears, using a position number which is faster than RenderTextToEnd if the number is precomputed at compile time 
; B - tile number of end character
; C - zero if drawn to background, non-zero if drawn to window 
; DE - position number to start writing at 
; HL - address to start of the text to write, make sure it contains the end character somewhere 
RenderTextToEndByPosition:
    ; For now, HL will store the address to write to, which we'll have to compute 
    push hl 
    call InitializePositionForBackgroundOrWindow
    add hl, de 
    
    ; Move this address onto DE so we can get the text address back 
    ld d, h
    ld e, l 
    pop hl 
    
    ; Start writing
    ld a, [hl]
.draw:
    WaitForNonBusyLCDSafeA
    ld [de], a 
    inc de 
    
    ; Check if the next character is the end character 
    inc hl 
    ld a, [hl]
    cp b 
    jr nz, .draw 
    
    ret 
    
; Draws text until a certain number of characters have been written, with positions as X/Y coordinates. This might be a bit slow for repeated use every frame.
; B - number of characters to write 
; C - drawing to background (0) or window (1) 
; D - X position 
; E - Y position 
; HL - address to start of text to write 
RenderTextToLength:
    ; Convert position coordinates to position number  
    push hl 
    
    xor a 
    ld h, a
    ld l, a 
    call XYtoPosition
    
    ; Put position number at DE and then restore HL 
    ld d, h 
    ld e, l  
    pop hl 
    
    call RenderTextToLengthByPosition
    ret 

; Draws text until a certain number of characters have been writtens, with position numbers using the formula pos = x + y*32
; If position numbers are precomputed at compile time, this will execute faster than RenderTextToLength
; B - number of characters to write 
; C - drawing to background (zero) or window (non-zero)
; DE - position number 
; HL - address to start of text to write 
RenderTextToLengthByPosition:
    push hl 
    ; For now, HL will store the position to write to 
    call InitializePositionForBackgroundOrWindow
    
    ; Add starting position onto background/window
    add hl, de 
    
    ; Now store this onto DE so we can get the read address back again 
    ld d, h
    ld l, e 
    pop hl 
     
.draw:
    ; Write characters until B is zero, decreasing it every time
    ld a, [hl+]
    WaitForNonBusyLCDSafeA ; Writing to VRAM needs to be timed 
    ld [de], a 
    inc de 
    
    dec b 
    ; Is B zero? If so we should stop 
    ld a, b 
    cp 0 
    ret z 
    
    jr .draw

; Internal function 
; Converts X and Y coordinates to a single position number by the formula pos = x + 32*y 
; D - X position 
; E - Y position 
; Output is added onto HL (which may be non-zero initially)
; Overwrites A 
XYtoPosition:
    ; Addition of 16-bit numbers require a full other 16-bit number to add. So we use BC for that here 
    push bc 
    
    ; Add X-position 
    ld c, d 
    ld b, 0 
    ; Now BC contains the X value as a 16-bit number 
    
    add hl, bc 
    
    ; Add Y-position if y>0
    ld a, e 
    cp 0 
    jr z, .end 
    
    ld c, e 
    ; Each line on the background/window is 32 tiles long, so to convert this to number of lines, we add the Y value 32 times) 
    REPT 32
    add hl, bc 
    ENDR 
    
.end:
    pop bc 
    ret 

; Draws two decimal (base 10) numbers, stored in a single 8-bit number (for example $42 would represent 42)
; A - The two numbers 
; B - Tile number of 0 (assuming that the rest of the digits follow, precisely in the order 0123456789)
; C - Zero if writing to background, non-zero if writing to window
; D - X position to write
; E - Y position to write
RenderTwoDecimalNumbers:     
    push af 
    push hl 
    
    ; Reset HL 
    xor a 
    ld h, a 
    ld l, a 
    
    call XYtoPosition
    
    ; The ByPosition call below expects the position number (now on HL) to be on DE
    ld d, h
    ld e, l 
    
    pop hl 
    pop af 
    
    call RenderTwoDecimalNumbersByPosition

    ret 

; Internal function 
; Sets HL to either the start of background map data or window map data, depending on C
; C - zero for background, non-zero for window 
InitializePositionForBackgroundOrWindow:
    ld a, c 
    cp 0 
    jr nz, .useWindow
    
.useBackground:
    ld hl, BACKGROUND_MAPDATA_START
    ret
    
.useWindow:    
    ld hl, WINDOW_MAPDATA_START
    ret 
    
; Draws two decimal (base 10) numbers, stored in a single 8-bit number (for example $42 would represent 42)
; Unlike RenderTwoDecimalNumbers, the position input here is a position number. This executes faster if the number is precomputed 
; and is thus recommended if the game displays lots of text and/or numbers every frame.
; A - The two numbers 
; B - Tile number of 0 (assuming that the rest of the digits follow, precisely in the order 0123456789)
; C - Zero if writing to background, non-zero if writing to window
; DE - Position number   
RenderTwoDecimalNumbersByPosition:
    push hl ; Use HL for temporary storage 
    push af ; To store the original two numbers to write
    
    ; Set HL to base address for background/window depending on value in C 
    call InitializePositionForBackgroundOrWindow
    
.draw:    
    ; To get the correct position, we add the position number onto HL  
    add hl, de 

    pop af 
    
    ; We don't need C anymore so we can use it to temporarily store the two numbers to write 
    ld c, a 
    
    ; Get the leftmost number first 
    and %11110000
    swap a 
    
    ; Convert to tile number 
    add b 
    
    ; Write the number 
    WaitForNonBusyLCDSafeA
    ld [hl+], a 
    
    ; Get the rightmost number 
    ld a, c 
    and %00001111
    
    ; Convert to tile number 
    add b
    
    ; Write the number 
    WaitForNonBusyLCDSafeA
    ld [hl], a 
    
    pop hl 
    ret 

; Draws four decimal (base 10) numbers, stored in a 16-bit number (for example $1234 would represent 1234)
; HL - The four numbers 
; B - Tile number of 0 (assuming that the rest of the digits follow, precisely in the order 0123456789)
; C - Zero if writing to background, non-zero if writing to window
; D - X position to write
; E - Y position to write    
RenderFourDecimalNumbers:
    ; Write the leftmost numbers first 
    ld a, h
    
    push bc 
    push de 
    push hl 
    
    call RenderTwoDecimalNumbers
    
    pop hl 
    pop de 
    pop bc 
    
    ; Move "x" two steps to the right 
    inc d
    inc d
    
    ; Then draw the rightmost numbers
    ld a, l 
    call RenderTwoDecimalNumbers
    
    ret 

; Draws four decimal (base 10) numbers, stored in a 16-bit number (for example $1234 would represent 1234)
; Unlike RenderFourDecimalNumbers, this function uses position numbers computed by pos = x + 32*y which will be 
; faster if this number is precomputed.
; HL - The four numbers 
; B - Tile number of 0 (assuming that the rest of the digits follow, precisely in the order 0123456789)
; C - Zero if writing to background, non-zero if writing to window
; DE - Position number of first number     
RenderFourDecimalNumbersByPosition:
    ld a, h ; The leftmost two numbers 
    
    push bc 
    push de 
    push hl 
    
    call RenderTwoDecimalNumbersByPosition
    
    pop hl 
    pop de 
    pop bc 
    
    ; Move position two steps to the right 
    inc de 
    inc de 
    
    ld a, l ; The rightmost two numbers 
    call RenderTwoDecimalNumbersByPosition
    
    ret 
    
; --- Save data ---

; Allows save data to become accessible to read and write. Note that save data is disabled by default. It also must be supported by 
; your cartidge and game header for this to work.
EnableSaveData:
    ld a, $0A
    ld [SAVEDATA], a 
    
    ret  

; Disables save data. Do this as soon as you are done using SRAM, to prevent data loss in case of a crash.    
DisableSaveData:
    xor a 
    ld [SAVEDATA], a
    
    ret 

; Assuming your game uses MBC5, having different numbers on A (between $00 and $0F) will activate different
; save data banks. Do this before running EnableSaveData.    
ChooseSaveDataBank:
    ld [MBC5_RAMB], a 
    
    ret 

; --- Super Game Boy functionality ---
IF DEF(SGB_SUPPORT)

SECTION "SGB Messages",ROMX,BANK[1]
SGB_OUT_ADDRESS EQU $FF00

SGB_SEND_ZERO   EQU %00100000
SGB_SEND_ONE    EQU %00010000
SGB_SEND_RESET  EQU %00000000
SGB_SEND_NULL   EQU %00110000

SGB_FREEZE:
DB %10111001    ; MASK_EN command, length one
DB 1            ; Freeze current image
DB 0
DB 0 
DB 0 
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0 

SGB_UNFREEZE:   
DB %10111001    ; MASK_EN command, length one
DB 0            ; Unfreeze
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0 

SGB_MLTREQ1:
DB %10001001
DB 0 
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0  

SGB_MLTREQ2:
DB %10001001
DB 1
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0
DB 0  
DB 0  

SGB_VRAMTRANS_TILEDATA1:
DB %10011001	; CHR_TRN, length one
DB 0 			; lower tiles (we can have another set of 128 tiles by setting this to one)
DB 0
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0  
DB 0  

SGB_VRAMTRANS_TILEDATA2:
DB %10011001	; CHR_TRN, length one
DB 1 			; upper tiles 
DB 0
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0  
DB 0 

SGB_VRAMTRANS_TILEMAP:
DB %10100001	; PCT_TRN, length one
DB 0 			
DB 0
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0 
DB 0  
DB 0  

SGB_INIT1:
DB $79,$5D,$08,$00,$0B,$8C,$D0,$F4,$60,$00,$00,$00,$00,$00,$00,$00
SGB_INIT2:
DB $79,$52,$08,$00,$0B,$A9,$E7,$9F,$01,$C0,$7E,$E8,$E8,$E8,$E8,$E0
SGB_INIT3:
DB $79,$47,$08,$00,$0B,$C4,$D0,$16,$A5,$CB,$C9,$05,$D0,$10,$A2,$28
SGB_INIT4:
DB $79,$3C,$08,$00,$0B,$F0,$12,$A5,$C9,$C9,$C8,$D0,$1C,$A5,$CA,$C9
SGB_INIT5:
DB $79,$31,$08,$00,$0B,$0C,$A5,$CA,$C9,$7E,$D0,$06,$A5,$CB,$C9,$7E
SGB_INIT6:
DB $79,$26,$08,$00,$0B,$39,$CD,$48,$0C,$D0,$34,$A5,$C9,$C9,$80,$D0
SGB_INIT7:
DB $79,$1B,$08,$00,$0B,$EA,$EA,$EA,$EA,$EA,$A9,$01,$CD,$4F,$0C,$D0
SGB_INIT8:
DB $79,$10,$08,$00,$0B,$4C,$20,$08,$EA,$EA,$EA,$EA,$EA,$60,$EA,$EA

SECTION "SGB Exposed commands",ROM0 
SGBAbsolutelyFirstInit:
    call SGBStrangeInit
    ret

CheckIfSGB:
    call CheckSGB
    jr nc, .CISGB_notSGB
    
    ; If we get here, then we are running SGB
    ld a, 1 
    ld [RUNNING_ON_SGB], a 
    jr .CISGB_end
    
.CISGB_notSGB
    xor a 
    ld [RUNNING_ON_SGB], a 
    
    jr .CISGB_end
    
.CISGB_end
    ret

SGBEarlyExit: MACRO 
    ld a, [RUNNING_ON_SGB]
    cp 0 
    ret z 
ENDM

SGBStart:
    call SGBFreeze
    ret
    
SGBEnd:
    call SGBUnfreeze
    ret
    
SECTION "SGB Internal commands",ROMX,BANK[1]

SGBStrangeInit:
    ld hl, SGB_INIT1 
    call SGBSendData
    call SGBFinish
    
    ld hl, SGB_INIT2
    call SGBSendData
    call SGBFinish
    
    ld hl, SGB_INIT3 
    call SGBSendData
    call SGBFinish
    
    ld hl, SGB_INIT4 
    call SGBSendData
    call SGBFinish
    
    ld hl, SGB_INIT5
    call SGBSendData
    call SGBFinish
    
    ld hl, SGB_INIT6 
    call SGBSendData
    call SGBFinish
    
    ld hl, SGB_INIT7 
    call SGBSendData
    call SGBFinish
    
    ld hl, SGB_INIT8 
    call SGBSendData
    call SGBFinish
    
    ret 

SGBBorderTransferMacro: MACRO
    di
    call StopLCD
	
    ld hl, \1
    ld de, TILEDATA_START
    ld bc, 4096
    call mCopyVRAM

    ld hl, \3
    ld de, BACKGROUND_MAPDATA_START
    ld bc, 32*32
    call mVRAM
    
    call StartLCD
   
    halt
    
    ld hl, \2
    call SGBSendData
    call SGBFinish

    ei 
    
REPT 5	
    halt
ENDR	

ENDM

SGBFreeze:
    ld hl, SGB_FREEZE
    call SGBSendData
    call SGBFinish
    ret 
    
SGBUnfreeze:
    ld hl, SGB_UNFREEZE
    call SGBSendData
    call SGBFinish
    ret

; Input: HL - address to first byte to send
SGBSendData:
    di 
    ; Register use: 
    ; B - Byte currently sending
    ; C - Total number of bytes to send 
    ; D - Number of bits sent of current byte 

    ld a, [hl]
    ld b, a 
    
    ; Each packet should send 16 bytes 
    ld c, 16
    
    xor a 
    ld d, a 
    
    ; Prepare SGB for listening 
    ld a, SGB_SEND_RESET
    ld [SGB_OUT_ADDRESS], a 
    
    ld a, SGB_SEND_NULL
    ld [SGB_OUT_ADDRESS], a 
     
SGBSendBit:
    inc d 
    ld a, d 
    cp 9 
    jr z, SGBEndOfByte

    ld a, b 
    and %00000001
    cp 0 
    jr z, SGBSendZeroBit
    
    ; Send a ONE bit here 
    ld a, SGB_SEND_ONE
    ld [SGB_OUT_ADDRESS], a 
    jr SGBSendBitEnd
    
SGBSendZeroBit:
    ld a, SGB_SEND_ZERO
    ld [SGB_OUT_ADDRESS], a 
    
SGBSendBitEnd:
    ; Both P14 and P15 should be HIGH in between sent bits 
    ld a, SGB_SEND_NULL 
    ld [SGB_OUT_ADDRESS], a 
        
    ld a, b 
    sra a 
    and %01111111
    ld b, a 
    
    jr SGBSendBit
    
SGBEndOfByte:
    dec c 
    ld a, c 
    cp 0 
    jr z, SGBFinalEnd
    
    ; If there are still bytes to send, we get here 
    inc hl 
    ld a, [hl]
    ld b, a 
    
    xor a 
    ld d, a 
    
    jr SGBSendBit
    
SGBFinalEnd:    
    ret 
    
SGBFinish:
    ld a, SGB_SEND_ZERO
    ld [SGB_OUT_ADDRESS], a 
    
    ld a, SGB_SEND_NULL
    ld [SGB_OUT_ADDRESS], a
    
    ei
    call Wait7000
    ret 
    
Wait7000:
    ld de, 7000 ; Each loop takes 9 cycles so this routine actually waits 63000 cycles.
.loop
	nop
	nop
	nop
	dec de
	ld a, d
	or e
	jr nz, .loop
	ret
    
CheckSGB:
; Returns whether the game is running on an SGB in carry.
	ld hl, SGB_MLTREQ2
	call SGBSendData
	call SGBFinish
	di
	ld a, 1
	ld [$FFF9], a
	ei
	call Wait7000
	ld a, [SGB_OUT_ADDRESS]
	and $3
	cp $3
	jr nz, .isSGB
	ld a, $20
	ld [SGB_OUT_ADDRESS], a
	ld a, [SGB_OUT_ADDRESS]
	ld a, [SGB_OUT_ADDRESS]
	call Wait7000
	call Wait7000
	ld a, $30
	ld [SGB_OUT_ADDRESS], a
	call Wait7000
	call Wait7000
	ld a, $10
	ld [SGB_OUT_ADDRESS], a
	ld a, [SGB_OUT_ADDRESS]
	ld a, [SGB_OUT_ADDRESS]
	ld a, [SGB_OUT_ADDRESS]
	ld a, [SGB_OUT_ADDRESS]
	ld a, [SGB_OUT_ADDRESS]
	ld a, [SGB_OUT_ADDRESS]
	call Wait7000
	call Wait7000
	ld a, $30
	ld [SGB_OUT_ADDRESS], a
	ld a, [SGB_OUT_ADDRESS]
	ld a, [SGB_OUT_ADDRESS]
	ld a, [SGB_OUT_ADDRESS]
	call Wait7000
	call Wait7000
	ld a, [SGB_OUT_ADDRESS]
	and $3
	cp $3
	jr nz, .isSGB
	call SendMltReq1Packet
	and a
	ret
.isSGB
	call SendMltReq1Packet
	scf
	ret    

SendMltReq1Packet:
    ld hl, SGB_MLTREQ1
    call SGBSendData
    call SGBFinish
    jp Wait7000

ENDC ; End of Super Game Boy functionality 

    
; --- Boot process and interrupts ---
; Feel free to change interrupts if your game should use them

; Interrupts
SECTION	"vblank interrupt",ROM0[$0040]
    jp	DMACODE_START ; sprites should be updated on every vblank
SECTION	"LCDC interrupt",ROM0[$0048]
    reti
SECTION	"Timer overflow interrupt",ROM0[$0050]
    reti
SECTION	"Serial interrupt",ROM0[$0058]
    reti
SECTION	"p1234 interrupt",ROM0[$0060]
    reti

; These are the first lines the boot loader will run. 
SECTION	"GingerBread start",ROM0[$0100]
    nop
    jp	GingerBreadBegin

    
SECTION "GingerBread Technical stuff, DMA and stop/start LCD",ROM0    
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
    ; It makes the background map be at $9800-$9BFF, while the window (which is off) be at $9C00-9FFF, which 
    ; is consistent with the definitions of BACKGROUND_MAPDATA_START and WINDOW_MAPDATA_START
    ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINOFF
	ld	[rLCDC], a
    ret     
    
TurnOnWindow:
    ; Same as StartLCD except the window is on. Turn it off by calling StartLCD (which doesn't hurt calling even when the LCD is already on)
    ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINON
	ld	[rLCDC], a
    ret    

SECTION "GingerBread boot",ROMX

; This function is called right at the start of the game. Calling or jumping to this function later should be equivalent to resetting the game.
; It resets RAM and various graphical settings.
GingerBreadBegin:
    nop 
    di
    
    ; Initialize stack pointer
    ld	sp, $ffff 
    
    ; Reset RAM 
    ld hl, RAM_START
    ld bc, $0FFF
    xor a 
    call mSet 
    
    ; Initialize display
    call StopLCD
    call initdma
    
    ld	a, IEF_VBLANK ; We only want vblank interrupts (for updating sprites)
    ld	[rIE], a 
    
    ei
    
    ; Reset VRAM 
    ld hl, TILEDATA_START
    ld bc, $1FFF
    xor a 
    call mSet 
    
    ; Set default palettes
    ld a, %11100100
    ld [BG_PALETTE], a
    ld [SPRITE_PALETTE_1], a
    ld [SPRITE_PALETTE_2], a 
    
    ; Reset sprites
    ld   hl, SPRITES_START
    ld   bc, SPRITES_LENGTH
    xor a 
    call mSet
    
    ; Set background position (no scrolling)
    xor a 
    ld [SCROLL_X], a 
    ld [SCROLL_Y], a 

    jp begin ; GingerBread assumes that your game has this label somewhere where your own code should start 

    