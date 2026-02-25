INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

SECTION "Player Variables", WRAM0
PLAYER_VEL::        DB
PLAYER_VEL_MAX::    DB
PLAYER_ANGLE::      DB
PLAYER_POS_X::      DW   ;Q12.4 (litte endian)
PLAYER_POS_Y::      DW   ;Q12.4 (litte endian)
PLAYER_HEALTH::     DB
PLAYER_DAMAGE::     DB
PLAYER_SHOT_FREC::  DB
PLAYER_SHOT_VEL::   DB

SECTION "Graphics", ROM0
playerTiles: INCBIN "src/generated/sprites/player.2bpp"
playerTilesEnd:

PlayerMetasprite::
  db 16, 8, 0, 0
  db 12, 16, 0, 0
  db 128 ; Metasprite end


SECTION "Player Entity", ROM0
; Inicializa el jugador.
Player_init::
    ; Copiar tiles del player
	ld de, playerTiles
	ld hl, _VRAM8000
	ld bc, playerTilesEnd - playerTiles ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

    ; Inicializamos los atributos del jugador
    xor a

    ld [PLAYER_POS_X], a
    ld [PLAYER_POS_X + 1], a

    ld [PLAYER_POS_Y], a
    ld [PLAYER_POS_Y + 1], a

    ld a, PLAYER_INIT_VEL_MAX
    ld [PLAYER_VEL_MAX], a

    ld a, ANGLE_NULL
    ld [PLAYER_ANGLE], a

    ld a, PLAYER_INIT_VEL
    ld [PLAYER_VEL], a

    ret



; Encargado de actualizar y llamar a las rutinas para
; el movimiento, las colisiones, los disparos y el
; renderizado del jugador principal.
Player_update_logic::
    ; Obtener ángulo de movimiento
    ld a, [wCurKeys]

    ;DEBUG, FORZAMOS MOVIMIENTO DER
    ;ld a, PADF_RIGHT

    ; ---- RIGHT + UP ----
    ld d, a
    and PADF_RIGHT | PADF_UP
    cp PADF_RIGHT | PADF_UP
    jr z, .angle45

    ; ---- RIGHT + DOWN ----
    ld a, d
    and PADF_RIGHT | PADF_DOWN
    cp PADF_RIGHT | PADF_DOWN
    jr z, .angle315

    ; ---- LEFT + UP ----
    ld a, d
    and PADF_LEFT | PADF_UP
    cp PADF_LEFT | PADF_UP
    jr z, .angle135

    ; ---- LEFT + DOWN ----
    ld a, d
    and PADF_LEFT | PADF_DOWN
    cp PADF_LEFT | PADF_DOWN
    jr z, .angle225

    ; ---- Cardinales ----
    ld a, d
    and PADF_RIGHT
    jr nz, .angle0

    ld a, d
    and PADF_LEFT
    jr nz, .angle180

    ld a, d
    and PADF_UP
    jr nz, .angle90

    ld a, d
    and PADF_DOWN
    jr nz, .angle270

    ; ---- Sin input ----
    ld b, ANGLE_NULL
    jr .angleDone

.angle0:
    ld b, ANGLE_0DEG
    jr .angleDone

.angle45:
    ld b, ANGLE_45DEG
    jr .angleDone

.angle90:
    ld b, ANGLE_90DEG
    jr .angleDone

.angle135:
    ld b, ANGLE_135DEG
    jr .angleDone

.angle180:
    ld b, ANGLE_180DEG
    jr .angleDone

.angle225:
    ld b, ANGLE_225DEG
    jr .angleDone

.angle270:
    ld b, ANGLE_270DEG
    jr .angleDone

.angle315:
    ld b, ANGLE_315DEG

.angleDone:
    ld a, b
    ld [PLAYER_ANGLE], a

    ; Comprobar si hay input
    cp ANGLE_NULL
    jr z, .noInputPhysics

    ; Computar velocidad
    ld a, [PLAYER_VEL]
    ld c, a
    call PhysicsEngine_computeVelocity

    ; Escalar velocidades para movimiento suave, ya que 
    ; la tabla de seno y coseno tiene valores muy grandes
    ; para los Q12.4 que usa RenderMetasprite
    srl b
    rr c
    srl b
    rr c
    srl b
    rr c
    srl b
    rr c

    srl d
    rr e
    srl d
    rr e
    srl d
    rr e
    srl d
    rr e

    jr .applyMovement

.noInputPhysics:
    ; Sin input, vel=0
    xor a
    ld b, a
    ld c, a
    ld d, a
    ld e, a

.applyMovement:
    ; $0A09
    ; Calcular nueva posición:
    ; pos_y = pos_y + vel_y
    ld a, [PLAYER_POS_Y + 1]
    ld h, a
    ld a, [PLAYER_POS_Y]
    ld l, a

    add hl, bc

    ; guardamos pos_y
    ld a, h
    ld [PLAYER_POS_Y + 1], a
    ld a, l
    ld [PLAYER_POS_Y], a
    
    ; pos_x = pos_x + vel_x
    ld a, [PLAYER_POS_X + 1]
    ld h, a
    ld a, [PLAYER_POS_X]
    ld l, a
    
    add hl, de

    ld a, h
    ld [PLAYER_POS_X + 1], a
    ld a, l
    ld [PLAYER_POS_X], a
    
    ; TODO:
    call PhysicsEngine_check_collision

    ; Renderizamos el metasprite
    ld a, [PLAYER_POS_Y + 1]
    ld b, a
    ld a, [PLAYER_POS_Y]
    ld c, a

    ld a, [PLAYER_POS_X + 1]
    ld d, a
    ld a, [PLAYER_POS_X]
    ld e, a
    
	ld hl, PlayerMetasprite
	call RenderMetasprite
    
    ret


