INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

SECTION "Player Variables", WRAM0
PLAYER_VEL::        DB
PLAYER_ANGLE::      DB
ESCALED_SCX::       DW   ;Q12.4 (litte endian)
ESCALED_SCY::       DW   ;Q12.4 (litte endian)
PLAYER_HEALTH::     DB

SECTION "Graphics", ROM0
playerTiles: INCBIN "src/generated/sprites/player.2bpp"
playerTilesEnd:

PlayerMetasprite::
  db 16, 8, 0, 0
  db 24, 8, 1, 0
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

    ld [PLAYER_VEL], a

    ld a, LOW(74<<4)
    ld [PLAYER_POS_X], a 
    ld a, HIGH(74<<4)
    ld [PLAYER_POS_X + 1], a

    ld a, LOW(64<<4)
    ld [PLAYER_POS_Y], a
    ld a, HIGH(64<<4)
    ld [PLAYER_POS_Y + 1], a

    ld a, ANGLE_NULL
    ld [PLAYER_ANGLE], a

    ret

; Encargado de actualizar y llamar a las rutinas para
; el movimiento, las colisiones, los disparos y el
; renderizado del jugador principal.
Player_update_logic::
    ; Obtener ángulo de movimiento
    ld a, [wCurKeys]
    ld d, a

    ; ---- RIGHT + UP ----
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
    call PhysicsEngine_computeVelocity

    jr .applyMovement

.noInputPhysics:
    xor a
    ld b, a
    ld c, a
    ld d, a
    ld e, a

.applyMovement:
    ; Calcular nueva posición:
    ; escaled_scy = esc_scy + vel_y
    ld a, [ESCALED_SCY + 1]
    ld h, a
    ld a, [ESCALED_SCY]
    ld l, a

    add hl, bc
    ; Escalar y volcar en SCY
    sra h
    rr l
    sra h
    rr l
    sra h
    rr l
    sra h
    rr l

    ld a, l
    ld [rSCY], a


    ; guardamos pos_y
    ld a, h
    ld [rSCY + 1], a
    ld a, l
    ld [rSCY], a
    
    ; pos_x = pos_x + vel_x
    ld a, [rSCX + 1]
    ld h, a
    ld a, [rSCX]
    ld l, a
    
    add hl, de

    ld a, h
    ld [rSCX + 1], a
    ld a, l
    ld [rSCX], a
    
    call PhysicsEngine_check_collision

    ; Renderizamos el metasprite
    ld b, HIGH(64<<4)
    ld c, LOW(64<<4)

    ld d, HIGH(74<<4)
    ld e, LOW(74<<4)
    
	ld hl, PlayerMetasprite
	jp RenderMetasprite
    
    ;ret


