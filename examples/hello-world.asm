; This section is for including files that either need to be in the home section, or files where it doesn't matter 
SECTION "Includes@home",ROM0

; Prior to importing GingerBread, some options can be specified

; Max 15 characters, should be uppercase ASCII
GAME_NAME EQUS "HIWORLD " 

; Include SGB support in GingerBread. This makes the GingerBread library take up a bit more space on ROM0. To remove support, comment out this line (don't set it to 0)
;SGB_SUPPORT EQU 1 

; Include GBC support in GingerBread. This makes the GingerBread library take up slightly more space on ROM0. To remove support, comment out this line (don't set it to 0)
;GBC_SUPPORT EQU 1

; Set the size of the ROM file here. 0 means 32 kB, 1 means 64 kB, 2 means 128 kB and so on.
ROM_SIZE EQU 1 

; Set the size of save RAM inside the cartridge. 
; If printed to real carts, it needs to be small enough to fit. 
; 0 means no RAM, 1 means 2 kB, 2 -> 8 kB, 3 -> 32 kB, 4 -> 128 kB 
RAM_SIZE EQU 1

INCLUDE "gingerbread.asm"
INCLUDE "images/hello_world.inc"

SECTION "Text definitions",ROM0 
; Charmap definition (based on the hello_world.png image, and looking in the VRAM viewer after loading it in BGB helps finding the values for each character)
CHARMAP "A",$14
CHARMAP "B",$15
CHARMAP "C",$16
CHARMAP "D",$17
CHARMAP "E",$18
CHARMAP "F",$19
CHARMAP "G",$1A
CHARMAP "H",$1B
CHARMAP "I",$1C
CHARMAP "J",$1D
CHARMAP "K",$1E
CHARMAP "L",$1F
CHARMAP "M",$20
CHARMAP "N",$21
CHARMAP "O",$22
CHARMAP "P",$23
CHARMAP "Q",$24
CHARMAP "R",$25
CHARMAP "S",$26
CHARMAP "T",$27
CHARMAP "U",$28
CHARMAP "V",$29
CHARMAP "W",$2A
CHARMAP "X",$2B
CHARMAP "Y",$2C
CHARMAP "Z",$2D
CHARMAP "<happy>",$02
CHARMAP "<sad>",$03
CHARMAP "<heart>",$04
CHARMAP "<up>",$07
CHARMAP "<down>",$08
CHARMAP "<left>",$06
CHARMAP "<right>",$05
CHARMAP " ",$00
CHARMAP "<end>",$30 ; Choose some non-character tile that's easy to remember 

SomeText:
DB "HELLO WORLD <happy><end>"

SECTION "StartOfGameCode",ROM0    
begin: ; GingerBread assumes that the label "begin" is where the game should start
    
    ld hl, hello_world_tile_data
    ld de, TILEDATA_START
    ld bc, hello_world_tile_data_size
    call mCopyVRAM

    ld b, $30 ; end character 
    ld c, 0 ; draw to background
    ld d, 4 ; X start position (0-19)
    ld e, 8 ; Y start position (0-17)
    ld hl, SomeText ; text to write 
    call RenderTextToEnd
    
    call StartLCD
    
main:
    halt 
    nop 
    
    jr main
