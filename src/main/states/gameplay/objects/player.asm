INCLUDE "src/main/utils/hardware.inc"

SECTION "PlayerVariables", WRAM0
PLAYER_MOMENTUM_MAX:: db ; SOLO SON UTILIZABLES LOS 7 PRIMEROS BITS: [0, 127]
PLAYER_MOMENTUM_X:: db ; BIT 7: 0 LEFT 1 RIGHT | BIT 6-0: SPEED [0, 127]
PLAYER_MOMENTUM_Y:: db ; BIT 7: 0 UP 1 DOWN | BIT 6-0: SPEED [0, 127]
PLAYER_MOMENTUM_INCREMENT:: db
PLAYER_MOMENTUM_DECREMENT:: db

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

    ; Momentum init
    ld a, 20
    ld [PLAYER_MOMENTUM_MAX], a
    ld a, 4
    ld [PLAYER_MOMENTUM_INCREMENT], a
    ld a, 2
    ld [PLAYER_MOMENTUM_DECREMENT], a
    xor a
    ld [PLAYER_MOMENTUM_X], a
    ld [PLAYER_MOMENTUM_Y], a

    ret


UpdatePlayer::
    call UpdateInputKeys
    call computeMomentum
    call movePlayer momentumToScroll

computeMomentum:
    ; Siempre se decrementa el momento, de tal forma que el personaje vaya perdiendo
    ; velocidad si no hay input por parte del jugador.
    ld a, [PLAYER_MOMENTUM_DECREMENT]
    ld b, a
    ld a, [PLAYER_MOMENTUM_X]
    sub a, b
    jp nc, .noUnderflowX
    xor a
.noUnderflowX:
    ld [PLAYER_MOMENTUM_X], a

    ld a, [PLAYER_MOMENTUM_Y]
    sub a, b
    jp nc, .noUnderflowY
    xor a
.noUnderflowY:
    ld [PLAYER_MOMENTUM_Y], a

    ; Computar el momento en base al input
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight

    ; Si el bit de dirección es 0 (movimiento izq), añadir momento. En otro caso decrementarlo hasta 0.
    ld a, [PLAYER_MOMENTUM_INCREMENT]
    ld b, a
    ld a, [PLAYER_MOMENTUM_MAX]
    ld c, a
    ld a, [PLAYER_MOMENTUM_X]

    ;if(mom.x.dir == left) 
    ;   mom.x.val = (mom.x.val + mom_increment) > mom_max ? mom_max : mom.x.val + mom_increment; 
    ;else {
    ;   mom.x.val = (mom.x.val - mom_increment) < 0 ? 0 : mom.x.val - mom_increment
    ; };
    bit 7, a           
    jp nz, .notLeft 
    
    ; Como MOM_X solo usa 7b para el valor del momento, podemos permitir que use el siguiente, y así
    ; solo debemos comparar si MOM_X < MOM_MAX, que automáticamente fallará si es mayor o si hay overflow (
    ; hemos usado el bit más significativo) ya que MOM_MAX [0-127].
    add a, b
    cp a, c
    jp c, .leftEnd
    ld a, [PLAYER_MOMENTUM_MAX]
    res 7, a ; Como hay overflow, A > MOM_MAX que puede ser 127, por lo que se habría usado el bit 7. Resetearlo a 0.
    jp .leftEnd

.notLeft:
    sub a, b
    jp nc, .leftEnd
    xor a

.leftEnd:
    ld [PLAYER_MOMENTUM_X], a

CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckDown

    ;jp moveRight

CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jp z, CheckUp
    
    ;jp moveDown

CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, checkEnd

    ;jp moveUp

checkEnd:
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
    ret

moveUp:
    ret

decrementMomentumX:
    ld a, [PLAYER_MOMENTUM_DECREMENT]
    ld b, a
    ld a, [PLAYER_MOMENTUM_X]
    sub a, b
    jp c, .BelowMin
    ld [PLAYER_MOMENTUM_X], a
.BelowMin:
    xor a
    ld [PLAYER_MOMENTUM_X], a
    ret

decrementMomentumY:
    ld a, [PLAYER_MOMENTUM_DECREMENT]
    ld b, a
    ld a, [PLAYER_MOMENTUM_Y]
    sub a, b
    jp c, .BelowMin
    ld [PLAYER_MOMENTUM_Y], a
.BelowMin:
    xor a
    ld [PLAYER_MOMENTUM_Y], a
    ret


; Aplica el momento del jugador en movimiento de scroll en pantalla
movePlayer:
    ld a, [PLAYER_MOMENTUM_X]
    cp a, 127
    ; momentum == 127
    jp z, checkX_end
    ; momentum < 127
    jp nc, leftMomentum
    ; momentum > 127
    ; Obtener momento real: |momentum - 127| -> momentum - 127
    ld b, 127
    sub a, b
    ld d, a

    ld a, [wBackgroundScroll_X+0]
	add a, d
	ld [wBackgroundScroll_X+0], a
    ld b, a
	ld a , [wBackgroundScroll_X+1]
	adc a , 0
	ld [wBackgroundScroll_X+1], a
    ld c, a

    call deEscaleBCtoA

    ld [wBackgroundScroll_X_real], a

    jp checkX_end

leftMomentum:
    ; Obtener momento real: |momentum - 127| -> 127 - momentum
    ld b, a
    ld a, 127
    sub a, b
    ld d, a

    ld a, [wBackgroundScroll_X+0]
	sub a, d
	ld [wBackgroundScroll_X+0], a
    ld b, a
	ld a , [wBackgroundScroll_X+1]
	sbc a , 0
	ld [wBackgroundScroll_X+1], a
    ld c, a

    call deEscaleBCtoA

    ld [wBackgroundScroll_X_real], a

checkX_end:

    ret
