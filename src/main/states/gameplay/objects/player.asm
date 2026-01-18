INCLUDE "src/main/utils/hardware.inc"

SECTION "PlayerVariables", WRAM0
PLAYER_MOMENTUM_MAX:: db ; SOLO SON UTILIZABLES LOS 7 PRIMEROS BITS: [0, 127]
PLAYER_MOMENTUM_X:: db ; BIT 7: 0 LEFT 1 RIGHT | BIT 6-0: SPEED [0, 127]
PLAYER_MOMENTUM_Y:: db ; BIT 7: 0 UP 1 DOWN | BIT 6-0: SPEED [0, 127]
PLAYER_MOMENTUM_INCREMENT:: db
PLAYER_MOMENTUM_DECREMENT:: db
DEBUG_10_RIGHT_MOVS:: db

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
    ld a, 40
    ld [PLAYER_MOMENTUM_MAX], a
    ld a, 4
    ld [PLAYER_MOMENTUM_INCREMENT], a
    ld a, 1
    ld [PLAYER_MOMENTUM_DECREMENT], a
    xor a
    ld [PLAYER_MOMENTUM_X], a
    ld [PLAYER_MOMENTUM_Y], a
    ; DEBUG
    ld a, 10
    ld [DEBUG_10_RIGHT_MOVS], a

    ret

; Lee inputs, calcula el momento y lo transforma en scroll
UpdatePlayer::
    call UpdateInputKeys
    call computeMomentum
    call momentumToScroll

    ret

computeMomentum:
    ; Siempre se decrementa el momento, de tal forma que el personaje vaya perdiendo
    ; velocidad si no hay input por parte del jugador.
    ; Tener en cuenta el bit de dirección
    ld a, [PLAYER_MOMENTUM_DECREMENT]
    ld b, a
    ld a, [PLAYER_MOMENTUM_X]
    ld c, a ; Almacenamos la codificación completa para luego recuperar el bit de dirección
    res 7, a ; Obtener valor real del momento
    sub a, b
    jp nc, .noUnderflowX
    xor a

.noUnderflowX:
    ; Añadir bit de dirección tras realizar el cálculo
    bit 7, c
    jp z, .isLeftMom
    set 7, a
.isLeftMom:
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

    ld a, [PLAYER_MOMENTUM_INCREMENT]
    ld b, a
    ld a, [PLAYER_MOMENTUM_MAX]
    ld c, a
    ld a, [PLAYER_MOMENTUM_X]

    ; En primer lugar, si el momento es 0, establecer el bit de dirección a left
    cp a, 128
    jp z, .momIsZero
    cp a, 0
    jp z, .momIsZero
    jp .momNotZero

.momIsZero:
    res 7, a

.momNotZero:
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
    ld a, [DEBUG_10_RIGHT_MOVS] ; DEBUG
    sub a, 1 ;DEBUG
    ld [DEBUG_10_RIGHT_MOVS], a ;DEBUG
    jp nc, forceRight ;DEBUG
    xor a ;DEBUG
    ld [DEBUG_10_RIGHT_MOVS], a ;DEBUG
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckDown

forceRight: ;DEBUG
    ld a, [PLAYER_MOMENTUM_INCREMENT]
    ld b, a
    ld a, [PLAYER_MOMENTUM_MAX]
    ld c, a
    ld a, [PLAYER_MOMENTUM_X]

    ; En primer lugar, si el momento es 0, establecer el bit de dirección a right
    cp a, 128
    jp z, .momIsZero
    cp a, 0
    jp z, .momIsZero
    jp .momNotZero

.momIsZero:
    set 7, a

.momNotZero:
    ; Igual que en left
    bit 7, a           
    jp z, .notRight
    res 7, a ; Obtener valor del momento
    add a, b
    cp a, c
    set 7, a ; Volver a establecer la dirección del momento
    jp c, .rightEnd
    ld a, [PLAYER_MOMENTUM_MAX]
    set 7, a ; Volver a establecer la dirección del momento

    jp .rightEnd

.notRight:
    sub a, b
    jp nc, .rightEnd
    xor a

.rightEnd:
    ld [PLAYER_MOMENTUM_X], a


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


; Convierte el momento del jugador en un desplazamiento de scroll
momentumToScroll:
    ld a, [PLAYER_MOMENTUM_X]
    ld d, a

    ; Comprobar si es movimiento izq o der
    ; Añadir el momento al entero escalado de scroll
    ; Obtener valor de scroll real
    bit 7, d
    jp nz, .rightMomentum

    ld a, [wBackgroundScroll_X+0]
	sub a, d
	ld [wBackgroundScroll_X+0], a
    ld b, a
	ld a, [wBackgroundScroll_X+1]
	sbc a, 0
	ld [wBackgroundScroll_X+1], a
    ld c, a

    jp bg_scroll_x_end


.rightMomentum:
    res 7, d    ; Borrar el bit de dirección para obtener valor del momento

    ld a, [wBackgroundScroll_X+0]
	add a, d
	ld [wBackgroundScroll_X+0], a
    ld b, a
	ld a, [wBackgroundScroll_X+1]
	adc a, 0
	ld [wBackgroundScroll_X+1], a
    ld c, a

bg_scroll_x_end:
    call deEscaleBCtoA
    ld [wBackgroundScroll_X_real], a

    ret
