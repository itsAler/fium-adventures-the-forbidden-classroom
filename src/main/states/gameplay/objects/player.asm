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

    ; Inicializamos la memoria OAM
	; ESTRUCTURA OAM -> [Y][X][TileIdx][Attributes: (b7:Priority)(b6:yFlip)(b5:xFlip)(b4:DMGPallete)(b3:Bank)(b2-0:CGBPallete)]
    ld hl, _OAMRAM
    ld a, 32 + 16   ; -> 16 offset inicial eje Y para y = 0 y 32 píxeles hacia abajo
    ld [hli], a     ; Y
    ld a, 16 + 8    
    ld [hli], a     ; X
    xor a
    ld [hli], a     ; TileID 0
    ld [hli], a     ; Attributes 0

    ret

UpdatePlayer::
    ret
