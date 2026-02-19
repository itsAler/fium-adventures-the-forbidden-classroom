INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

DEF ENT_PLAYER_INIT_MOMENTUM_MAX        EQU 60
DEF ENT_PLAYER_INIT_MOMENTUM_INC_DEC    EQU %11110001
DEF ENT_PLAYER_INIT_HEALTH              EQU 20
DEF ENT_PLAYER_INIT_DAMAGE              EQU 5

SECTION "player Specific Entity Variables", WRAM0
ENT_PLAYER_SHOOTING_FRECUENCY:: DB
ENT_PLAYER_BULLET_VELOCITY:: DB

SECTION "Player Entity", ROM0

playerTiles: INCBIN "src/generated/sprites/player.2bpp"
playerTilesEnd:

; Inicializa un jugador.
;
; init_data(entityList* et_free_space) returns none
; Destruye a, de, bc, hl
;
;
ent_player_init_data::
    push bc ; Contiene la dirección de la entrada a usar en la entityList

    call SpriteManager_add_sprite

    ; Copiar tiles del player
	ld de, playerTiles
	ld hl, _VRAM8000
	ld bc, playerTilesEnd - playerTiles ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

    ; TODO Mover al Sprite Manager
    ; Inicializamos la memoria shadowOAM
	; ESTRUCTURA OAM -> [Y][X][TileIdx][Attributes: (b7:Priority)(b6:yFlip)(b5:xFlip)(b4:DMGPallete)(b3:Bank)(b2-0:CGBPallete)]
    ld a, 32 + 16
    ld [wShadowOAM], a ; Y
    ld a, 16 + 8
    ld [wShadowOAM+1], a  ;X
    xor a
    ld [wShadowOAM+2], a ; TileID
    ld [wShadowOAM+3], a ; Attr

    ; TODO Mover al physics Engine
    ; Inicializamos los atributos del jugador
    pop hl ; Recuperamos puntero la entrada en EntityList

    xor a
    ld a, ENT_STATUS_VALID | ENT_TYPE_PLAYER
    ld [hli], a
    ld a, ENT_PLAYER_INIT_MOMENTUM_MAX
    ld [hli], a ; MOMENTUM_MAX    
    ld a, [ENT_PLAYER_INIT_MOMENTUM_INC_DEC]
    ld [hli], a
    ld a, [ENT_PLAYER_INIT_HEALTH]
    ld [hli], a
    ld a, [ENT_PLAYER_INIT_DAMAGE]
    ld [hli], a
    xor a
    ld [hli], a ; MOMENTUM_X
    ld [hli], a ; MOMENTUM_Y
    ld [hli], a ; SCALED_X_HB
    ld [hli], a ; SCALED_X_LB
    ld [hli], a ; SCALED_Y_HB
    ld [hli], a ; SCALED_Y_LB

    ret


; Lee inputs, calcula el momento del jugador y lo transforma en scroll
;
; update_logic(hl = entity_list* player) returns none;
;
; Destruye: 
ent_player_update::

    ; Obtener input actualizado del jugador
    ; Calcular el momento en base a dichos input
    ; Decrementar por rozamiento la inercia
    ; Comprobar si el jugador ha disparado una bala
    ; 

    call UpdateInputKeys


    ; Decrementa el momento (rozamiento) y calcula el momento del personaje en base al input del jugador

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
    ld c, a
    res 7, a
    sub a, b
    jp nc, .noUnderflowY
    xor a
.noUnderflowY:
    bit 7, c
    jp z, .isLeftMomY
    set 7, a
    .isLeftMomY:
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
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckDown

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
    
    ld a, [PLAYER_MOMENTUM_INCREMENT]
    ld b, a
    ld a, [PLAYER_MOMENTUM_MAX]
    ld c, a
    ld a, [PLAYER_MOMENTUM_Y]

    cp a, 128
    jp z, .momIsZero
    cp a, 0
    jp z, .momIsZero
    jp .momNotZero

.momIsZero:
    set 7, a

.momNotZero:
   ; Igual que en right
    bit 7, a           
    jp z, .notDown
    res 7, a ; Obtener valor del momento
    add a, b
    cp a, c
    set 7, a ; Volver a establecer la dirección del momento
    jp c, .downEnd
    ld a, [PLAYER_MOMENTUM_MAX]
    set 7, a ; Volver a establecer la dirección del momento (después de cargar mom_max)

    jp .downEnd

.notDown:
    sub a, b
    jp nc, .downEnd
    xor a

.downEnd:
    ld [PLAYER_MOMENTUM_Y], a

CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, checkEnd

    ld a, [PLAYER_MOMENTUM_INCREMENT]
    ld b, a
    ld a, [PLAYER_MOMENTUM_MAX]
    ld c, a
    ld a, [PLAYER_MOMENTUM_Y]

    cp a, 128
    jp z, .momIsZero
    cp a, 0
    jp z, .momIsZero
    jp .momNotZero

.momIsZero:
    res 7, a

.momNotZero:
    bit 7, a           
    jp nz, .notUp
    
    add a, b
    cp a, c
    jp c, .upEnd
    ld a, [PLAYER_MOMENTUM_MAX]
    res 7, a
    jp .upEnd

.notUp:
    sub a, b
    jp nc, .upEnd
    xor a

.upEnd:
    ld [PLAYER_MOMENTUM_Y], a

checkEnd:

; Convierte el momento del jugador en un desplazamiento de scroll
    ld a, [PLAYER_MOMENTUM_X]
    ld d, a

    ; Comprobar si es movimiento izq o der
    bit 7, d
    jp nz, .rightMomentum

    ; Añadir el momento al entero escalado de scroll
    ld a, [wBackgroundScroll_X+0]
	sub a, d
	ld [wBackgroundScroll_X+0], a
    ld b, a
	ld a, [wBackgroundScroll_X+1]
	sbc a, 0
	ld [wBackgroundScroll_X+1], a
    ld c, a

    ; Obtener valor de scroll real y volcar a screen
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


    ld a, [PLAYER_MOMENTUM_Y]
    ld d, a
    bit 7, d
    jp nz, .downMomentum

    ld a, [wBackgroundScroll_Y+0]
	sub a, d
	ld [wBackgroundScroll_Y+0], a
    ld b, a
	ld a, [wBackgroundScroll_Y+1]
	sbc a, 0
	ld [wBackgroundScroll_Y+1], a
    ld c, a

    jp bg_scroll_y_end

.downMomentum:
    res 7, d 

    ld a, [wBackgroundScroll_Y+0]
	add a, d
	ld [wBackgroundScroll_Y+0], a
    ld b, a
	ld a, [wBackgroundScroll_Y+1]
	adc a, 0
	ld [wBackgroundScroll_Y+1], a
    ld c, a

bg_scroll_y_end:
    call deEscaleBCtoA
    ld [wBackgroundScroll_Y_real], a

    ret
