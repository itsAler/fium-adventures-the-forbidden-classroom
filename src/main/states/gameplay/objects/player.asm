INCLUDE "src/main/utils/hardware.inc"


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
    ret

UpdatePlayer::
    ; Actualizar la entrada
    call UpdateInputKeys

    ; Comprobar la entrada
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
    ;Mover la cámara si no colisiona con un márgen
    ;ld a, [wShadowOAM+1]
    ;dec a
    ;ld [wShadowOAM+1], a

    ld a, [bgScroll_X]
    dec a
    ld [bgScroll_X], a
    jp checkEnd
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckDown
    ; Mover a la der.
    ;ld a, [wShadowOAM+1]
    ;inc a
    ;ld [wShadowOAM+1], a

    ld a, [bgScroll_X]
    inc a
    ld [bgScroll_X], a
    jp checkEnd
CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jp z, CheckUp
    ; Mover abajo
    ;ld a, [wShadowOAM]
    ;inc a
    ;ld [wShadowOAM], a

    ld a, [bgScroll_Y]
    inc a
    ld [bgScroll_Y], a
    jp checkEnd
CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, checkEnd
    ; Mover arriba
    ;ld a, [wShadowOAM]
    ;dec a
    ;ld [wShadowOAM], a
    ld a, [bgScroll_Y]
    dec a
    ld [bgScroll_Y], a
checkEnd:
    ld a, [bgScroll_X]
    ld [rSCX], a
    ld a, [bgScroll_Y]
    ld [rSCY], a
    ret