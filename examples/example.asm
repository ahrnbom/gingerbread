; ****************************************************************************************
; Define variables
; ****************************************************************************************
Variables_start  	        equ $D000
    
; Constants
BankSwitch              equ $2000       ; Write to this memory address to switch banks (screw you, SEB!)
SpritePalette           equ $FF48       ; Write to this memory address to change palette of sprites


; This section is for including files that either need to be in the home section, or files where it doesn't matter 
SECTION "Includes@home",HOME

INCLUDE "gingerbread.asm"

; This section is for including files that need to be in data banks
SECTION "Include@banks",DATA
INCLUDE "images/title.inc"
INCLUDE "images/pong.inc"


SECTION "header",HOME[$0104]
    ;ROM header, starting with "Nintendo" logo. If this is modified, the game won't start on a real Gameboy.
    DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
    DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
    DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

BeforeName:
    DB "SuperPingPong"    ; Cart name: up to 15 bytes 
AfterName:
    REPT    15-(AfterName-BeforeName) ; Pad the name with zeroes to make it 15 bytes
        DB	0
    ENDR	
    
    DB 	$80                 ; $143 - GBC functionality (0 for no, $80 for "black cart" and $C0 for GBC only)
    DB 	0,0                 ; $144 - Licensee code (not important)
    DB 	3                   ; $146 - SGB Support indicator (0 means no support, 3 means there is SGB support in the game)
    DB 	$1B                 ; $147 - Cart type ($1B means MBC5 with RAM and battery save)
    DB 	0                   ; $148 - ROM Size, 0 means 32 kB, 1 means 64 kB and so on up to 2 MB
    DB	1                   ; $149 - RAM Size, 0 means no RAM, 1 means 2 kB, 2 -> 8 kB, 3 -> 32 kB, 4 -> 128 kB
    DB 	1                   ; $14a - Destination code (0 means japan, 1 mean non-japan, doesn't matter)
    DB 	$33                 ; $14b - Old licensee code, needs to be $33 for SGB to work
    DB 	0                   ; $14c - Mask ROM version
    DB 	0                   ; $14d - Complement check (important, RGBDS takes care of this)
    DW 	0                   ; $14e - Checksum (not important, RGBDS takes care of this)


; Macro for copying a rectangular region into VRAM
; Changes ALL registers
; Arguments:
; 1 - Height (number of rows)
; 2 - Width (number of columns)
; 3 - Source to copy from
; 4 - Destination to copy to
CopyRegionToVRAM: MACRO

I SET 0
REPT \1

    ld bc, \2
    ld hl, \3+(I*\2)
    ld de, \4+(I*32)
    
    call mCopyVRAM
    
I SET I+1
ENDR
ENDM    
    
SECTION "StartOfGameCode",HOME    
begin: ; GingerBread assumes that the label "begin" is where the game should start
    nop 
    di
    
    ; Initialize stack pointer
    ld	sp, $ffff 
    
    ; Initialize display
    call StopLCD
    call initdma
    ld	a, IEF_VBLANK ; We only want vblank interrupts (for updating sprites)
    ld	[rIE],a 
    
    ei
    
    ; Set default palettes
    ld a, %11100100
    ld [BG_PALETTE], a
    ld [SPRITE_PALETTE_1], a
    ld [SPRITE_PALETTE_2], a 
    
    ; Reset sprites
    ld   hl, SPRITES_START
    ld   bc, SPRITES_LENGTH
    ld   a, 0
    call mSet
    
    ; Load title image into VRAM
    ; We don't need VRAM-specific memory function here, because LCD is off.
    ld a, BANK(title_tile_data)
    ld [BankSwitch], a
    
    ld hl, title_tile_data
    ld de, TILEDATA_START
    ld bc, title_tile_data_size
    call mCopy
    
    CopyRegionToVRAM 18, 20, title_map_data, MAPDATA_START
    
    call StartLCD
    
    ; Everything up to this point is simply an example demo which shows a single image. If you want
    ; to use this as your starting point, remove all lines below.
    
    call EnableAudio
    
; Definition of some RAM variables 
SECTION "RAM variables",WRAM0[$C100]
BALL_POSITION: DS 2
BALL_DIRECTION: DS 2 
LEFT_PADDLE_POSITION: DS 2
RIGHT_PADDLE_POSITION: DS 2  
RIGHT_PADDLE_CHECK_TIME: DS 1 
RIGHT_PADDLE_DIRECTION: DS 1

; Definition of some constants
PADDLE_SPEED                    equ 2 ; pixels per frame   
RIGHT_PADDLE_CHECK_FREQUENCY    equ 6 ; how many frame should pass between each check if right paddle should move up/down 

SECTION "Sound effect definitions",HOME
Sound_ball_bounce:
DW SOUND_CH4_START
DB %00000000 ; Data to be written to SOUND_CH4_START
DB %00000100 ; Data to be written to SOUND_CH4_LENGTH
DB %11110111 ; Data to be written to SOUND_CH4_ENVELOPE 
DB %01010101 ; Data to be written to SOUND_CH4_POLY 
DB %11000110 ; Data to be written to SOUND_CH4_OPTIONS

SECTION "Pong game code",HOME
TitleLoop:
    halt
    nop ; Always do a nop after a halt, because of a CPU bug
    
    call ReadKeys
    and KEY_A | KEY_START
    cp 0
    
    jp nz, TransitionToGame
    
    jr TitleLoop
    
ShortWait:
    ld b, 20
    
.loop:    
    halt 
    nop 
    
    dec b 
    ld a, b
    cp 0 
    jr nz, .loop 
    
    ret 

; Modifies AF
DrawBall:    
    ; Left part of ball
    ld a, [BALL_POSITION+1] ; Y location
    ld [SPRITES_START], a
    ld a, [BALL_POSITION] ; X location 
    ld [SPRITES_START+1], a 
    ld a, $56 ; Tile number 
    ld [SPRITES_START+2], a
    xor a ; Flags
    ld [SPRITES_START+3], a 
    
    ; Right part of ball
    ld a, [BALL_POSITION+1] ; Y location
    ld [SPRITES_START+4], a
    ld a, [BALL_POSITION] ; X location
    add 8 ; right part of ball should be 8 pixels to the right     
    ld [SPRITES_START+5], a 
    ld a, $58 ; Tile number 
    ld [SPRITES_START+6], a
    xor a ; Flags
    ld [SPRITES_START+7], a     
    
    ret

; Modifies AF
DrawLeftPaddle:
    ; Top part of paddle
    ld a, [LEFT_PADDLE_POSITION+1] ; Y
    ld [SPRITES_START+8], a
    ld a, [LEFT_PADDLE_POSITION] ; X
    ld [SPRITES_START+9], a
    ld a, $52 ; Top and top-middle paddle tiles
    ld [SPRITES_START+10], a 
    xor a 
    ld [SPRITES_START+11], a
    
    ; Bottom of paddle
    ld a, [LEFT_PADDLE_POSITION+1] ; Y
    add 16
    ld [SPRITES_START+12], a 
    ld a, [LEFT_PADDLE_POSITION] ; X
    ld [SPRITES_START+13], a 
    ld a, $54 ; Bottom-middle and bottom paddle tiles 
    ld [SPRITES_START+14], a 
    xor a 
    ld [SPRITES_START+15], a 
    
    ret

; Modifies AF
DrawRightPaddle:
    ; Top part of paddle
    ld a, [RIGHT_PADDLE_POSITION+1] ; Y
    ld [SPRITES_START+16], a
    ld a, [RIGHT_PADDLE_POSITION] ; X
    ld [SPRITES_START+17], a
    ld a, $52 ; Top and top-middle paddle tiles
    ld [SPRITES_START+18], a 
    xor a 
    ld [SPRITES_START+19], a
    
    ; Bottom of paddle
    ld a, [RIGHT_PADDLE_POSITION+1] ; Y
    add 16
    ld [SPRITES_START+20], a 
    ld a, [RIGHT_PADDLE_POSITION] ; X
    ld [SPRITES_START+21], a 
    ld a, $54 ; Bottom-middle and bottom paddle tiles 
    ld [SPRITES_START+22], a 
    xor a 
    ld [SPRITES_START+23], a 
    
    ret
    
TransitionToGame:
    ld a, %11111001
    ld [BG_PALETTE], a
    
    call ShortWait
    
    ld a, %11111110
    ld [BG_PALETTE], a
    
    call ShortWait
    
    ld a, %11111111
    ld [BG_PALETTE], a
    
    call ShortWait
    
    ; Now that the screen is completely black, load the game graphics
    
    ld a, BANK(title_tile_data)
    ld [BankSwitch], a
    
    ld hl, pong_tile_data
    ld de, TILEDATA_START
    ld bc, pong_tile_data_size
    call mCopyVRAM
    
    CopyRegionToVRAM 18, 20, pong_map_data, MAPDATA_START
    
    ; Now fade back to normal palette
    
    ld a, %11111110
    ld [BG_PALETTE], a
    
    call ShortWait
    
    ld a, %11111001
    ld [BG_PALETTE], a 
    
    call ShortWait
    
    ld a, %11100100
    ld [BG_PALETTE], a 
    
    call ShortWait
    
    ; Let's put the sprites in place
    
    ld a, 100 ; X
    ld [BALL_POSITION], a 
    ld a, 50 ; Y
    ld [BALL_POSITION+1], a
    call DrawBall
    
    ld a, 12 ; X
    ld [LEFT_PADDLE_POSITION], a
    ld a, 72 ; Y
    ld [LEFT_PADDLE_POSITION+1], a
    call DrawLeftPaddle
    
    ld a, 154 ; X
    ld [RIGHT_PADDLE_POSITION], a 
    ld a, 72 ; Y
    ld [RIGHT_PADDLE_POSITION+1], a 
    call DrawRightPaddle
    
    ; Set initial ball movement 
    ld a, 2 ; dx 
    ld [BALL_DIRECTION], a 
    ld a, 1 ; dy 
    ld [BALL_DIRECTION+1], a 
    
    ; Initialize right paddle check counter and direction 
    xor a 
    ld [RIGHT_PADDLE_CHECK_TIME], a 
    ld [RIGHT_PADDLE_DIRECTION], a 
    
    jp GameLoop 

; Modifies AF 
; Moves the left paddle up, making sure not to move it outside the playing field 
MoveLeftPaddleUp:
    ld a, [LEFT_PADDLE_POSITION+1]
    sub PADDLE_SPEED
    
    ; Check if too high up 
    cp 24
    ret c 
    
    ld [LEFT_PADDLE_POSITION+1], a 
    ret 

; Modifies AF
; Same as MoveLeftPaddleUp, except Down     
MoveLeftPaddleDown:    
    ld a, [LEFT_PADDLE_POSITION+1]
    add PADDLE_SPEED
    
    ; Check if too far down 
    cp 130
    ret nc
    
    ld [LEFT_PADDLE_POSITION+1], a
    ret 


; Modifies AF 
; Moves the right paddle up, making sure not to move it outside the playing field 
MoveRightPaddleUp:
    ld a, [RIGHT_PADDLE_POSITION+1]
    sub PADDLE_SPEED
    
    ; Check if too high up 
    cp 24
    ret c 
    
    ld [RIGHT_PADDLE_POSITION+1], a 
    ret 

; Modifies AF
; Same as MoveRightPaddleUp, except Down     
MoveRightPaddleDown:    
    ld a, [RIGHT_PADDLE_POSITION+1]
    add PADDLE_SPEED
    
    ; Check if too far down 
    cp 130
    ret nc
    
    ld [RIGHT_PADDLE_POSITION+1], a
    ret 

    
ReverseBallDY:
    ; 0 - dy will be a positive integer, but it still works because of overflow
    xor a 
    sub c 
    ld [BALL_DIRECTION+1], a 
    ret
    
ReverseBallDX:
    xor a 
    sub b 
    ld [BALL_DIRECTION], a 
    ret 

CheckCollisionLeftPaddle:
    ; First check if the ball is far enough to the left 
    ld a, [BALL_POSITION]
    cp 16
    ret nc 
    
    ; Now check if it's far enough down 
    ld a, [LEFT_PADDLE_POSITION+1]
    ld d, a 
    ld a, [BALL_POSITION+1]
    add 8
    cp d 
    ret c
    
    ; Now check if it's not too far down 
    sub 40
    cp d 
    ret nc 
    
    call ReverseBallDX
    
    ld hl, Sound_ball_bounce
    call PlaySoundHL
    
    ; To prevent ball from getting stuck, make sure dx > 0 and it's a bit to the right 
    ld a, [BALL_POSITION]
    add 2 
    ld [BALL_POSITION], a 
    
    ld a, [BALL_DIRECTION]
    cp 128
    ret c 
    
    ; If we get here, it means ball direction was wrong 
    call ReverseBallDX
    ret 
    
CheckCollisionRightPaddle:
    ; First check if the ball is far enough to the right 
    ld a, [BALL_POSITION]
    cp 142
    ret c 
    
    ; Now check if it's far enough down 
    ld a, [RIGHT_PADDLE_POSITION+1]
    ld d, a 
    ld a, [BALL_POSITION+1]
    add 8
    cp d 
    ret c
    
    ; Now check if it's not too far down 
    sub 40
    cp d 
    ret nc 
    
    call ReverseBallDX    
    
    ld hl, Sound_ball_bounce
    call PlaySoundHL
    
    ; To prevent ball from getting stuck, make sure dx < 0 and it's a bit to the left 
    ld a, [BALL_POSITION]
    sub 2 
    ld [BALL_POSITION], a 
    
    ld a, [BALL_DIRECTION]
    cp 128
    ret nc 
    
    ; If we get here, it means ball direction was wrong 
    call ReverseBallDX
    ret 
    
; Modifies AF and BC and DE  
UpdateBall:
    ; Store dx in B, and add to ball x
    ld a, [BALL_DIRECTION]
    ld b, a 
    ld a, [BALL_POSITION]
    add b 
    ld [BALL_POSITION], a 
    
    ; Store dy in C, and add to ball y 
    ld a, [BALL_DIRECTION+1]
    ld c, a 
    ld a, [BALL_POSITION+1]
    add c 
    ld [BALL_POSITION+1], a 
    
    ; Check if ball collides with ceiling, if so reverse dy
    ld a, [BALL_POSITION+1]
    cp 24
    call c, ReverseBallDY
    
    ; Same but for the floor
    ld a, [BALL_POSITION+1]
    cp 144
    call nc, ReverseBallDY
    
    ; Check collision with paddles 
    call CheckCollisionRightPaddle
    call CheckCollisionLeftPaddle
    
    ret 

RightPaddleStartMovingDown:
    ld a, 1 
    ld [RIGHT_PADDLE_DIRECTION], a 
    ret 
    
RightPaddleStartMovingUp:
    xor a 
    ld [RIGHT_PADDLE_DIRECTION], a
    ret 
    
UpdateRightPaddleDirection:    
    ; Reset check counter
    xor a 
    ld [RIGHT_PADDLE_CHECK_TIME], a 

    ; Compare ball's and right paddle's y values and move paddle accordingly
    ld a, [BALL_POSITION+1]
    sub 8 ; because paddle is taller than ball 
    ld b, a 
    ld a, [RIGHT_PADDLE_POSITION+1]
    push af 
    push bc 
    cp b
    call nc, RightPaddleStartMovingUp
    pop bc 
    pop af 
    cp b 
    call c, RightPaddleStartMovingDown
    
    ret 
    
UpdateRightPaddle:
    ld a, [RIGHT_PADDLE_DIRECTION] ; 0 means up, 1 means down 
    cp 0 
    jr z, .moveUp

.moveDown:
    call MoveRightPaddleDown
    ret

.moveUp:
    call MoveRightPaddleUp
    ret 
    
GameLoop:
    call DrawLeftPaddle
    call DrawRightPaddle
    call DrawBall

    halt 
    nop 
    
    call ReadKeys
    push af ; Store key status so it can be used twice 
    and KEY_UP
    cp 0 
    call nz, MoveLeftPaddleUp
    pop af 
    and KEY_DOWN
    cp 0 
    call nz, MoveLeftPaddleDown
    
    call UpdateBall
    
    ld a, [RIGHT_PADDLE_CHECK_TIME]
    inc a 
    ld [RIGHT_PADDLE_CHECK_TIME], a 
    cp RIGHT_PADDLE_CHECK_FREQUENCY
    call z, UpdateRightPaddleDirection 
    
    call UpdateRightPaddle
    
    jp GameLoop 