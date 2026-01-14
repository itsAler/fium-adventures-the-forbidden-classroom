INCLUDE "src/main/utils/hardware.inc"

SECTION "PlayerVariables", WRAM0
PLAYER_SPEED:: db


SECTION "GameplayPlayerSection", ROM0

playerTiles: INCBIN "src/generated/sprites/player.2bpp"
playerTilesEnd:


InitializePlayer::
    ; Copiar tiles del player
	ld de, playerTiles
	ld hl, _VRAM8000
	ld bc, playerTilesEnd - playerTiles ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

    ; Inicializamos la memoria shadowOAM
	; ESTRUCTURA OAM -> [Y][X][TileIdx][Attributes: (b7:Priority)(b6:yFlip)(b5:xFlip)(b4:DMGPallete)(b3:Bank)(b2-0:CGBPallete)]
    ld a, 32 + 16
    ld [wShadowOAM], a ; Y
    ld a, 16 + 8
    ld [wShadowOAM+1], a  ;X
    xor a
    ld [wShadowOAM+2], a ; TileID
    ld [wShadowOAM+3], a ; Attr 

    ld a, 8
    ld [PLAYER_SPEED], a

    ret

UpdatePlayer::

    call UpdateInputKeys
    ld hl, PLAYER_SPEED

CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
    
    jp moveLeft

CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckDown

    jp moveRight

CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jp z, CheckUp
    
    jp moveDown

CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, checkNone

    jp moveUp

checkNone:
    ret


moveLeft:
	; mBackGroundScroll tiene 2 bytes en little endian: [LSB][MSB] -> 0x[MSB][LSB]
	; ADC tiene en cuenta si la suma/resta en el LSB ha desbordado y añade/quita 1 en MSB
	ld a, [wBackgroundScroll_X+0]
	sub a, [hl]
	ld [wBackgroundScroll_X+0], a
    ld b, a
	ld a , [wBackgroundScroll_X+1]
	sbc a , 0
	ld [wBackgroundScroll_X+1], a
    ld c, a

    call deEscaleBCtoA

    ld [wBackgroundScroll_X_real], a

    ret

moveRight:
    ld a, [wBackgroundScroll_X+0]
	add a, [hl]
	ld [wBackgroundScroll_X+0], a
    ld b, a
	ld a , [wBackgroundScroll_X+1]
	adc a , 0
	ld [wBackgroundScroll_X+1], a
    ld c, a

    call deEscaleBCtoA

    ld [wBackgroundScroll_X_real], a
    ret

moveDown:
    ld a, [wBackgroundScroll_Y+0]
	add a, [hl]
	ld [wBackgroundScroll_Y+0], a
    ld b, a
	ld a , [wBackgroundScroll_Y+1]
	adc a , 0
	ld [wBackgroundScroll_Y+1], a
    ld c, a

    call deEscaleBCtoA

    ld [wBackgroundScroll_Y_real], a
    ret

moveUp:
    ld a, [wBackgroundScroll_Y+0]
	sub a, [hl]
	ld [wBackgroundScroll_Y+0], a
    ld b, a
	ld a , [wBackgroundScroll_Y+1]
	sbc a , 0
	ld [wBackgroundScroll_Y+1], a
    ld c, a

    call deEscaleBCtoA

    ld [wBackgroundScroll_Y_real], a
    ret


