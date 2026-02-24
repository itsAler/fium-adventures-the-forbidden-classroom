INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

; Player Constants
DEF ENT_PLAYER_INIT_VEL_MAX EQU 60
DEF ENT_PLAYER_INIT_HEALTH  EQU 20
DEF ENT_PLAYER_INIT_DAMAGE  EQU 5
DEF ENT_PLAYER_INIT_VEL_INC EQU 16

SECTION "Player Variables", WRAM0
PLAYER_VEL::        DB
PLAYER_VEL_MAX::    DB
PLAYER_ANGLE::      DB
PLAYER_POS_X::      DW   ;Q12.4
PLAYER_POS_Y::      DW   ;Q12.4
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
; Inicializa un jugador.
;
; init_data(entityList* et_free_space) returns none
; Destruye a, de, bc, hl
;
;
Player_init::
    ; Copiar tiles del player
	ld de, playerTiles
	ld hl, _VRAM8000
	ld bc, playerTilesEnd - playerTiles ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

    ; Inicializamos los atributos del jugador
    xor a
    ld [PLAYER_VEL], a

    ld [PLAYER_ANGLE], a

    ld [PLAYER_X], a
    ld [PLAYER_X + 1], a

    ld [PLAYER_Y], a
    ld [PLAYER_Y + 1], a

    ld a, [PLAYER_INIT_VEL_MAX]
    ld [PLAYER_VEL_MAX], a

    ret



; Encargado de actualizar y llamar a las rutinas para
; el movimiento, las colisiones, los disparos y el
; renderizado del jugador principal.
Player_update_logic::
    ; Obtener ángulo de movimiento
    ld a, [PLAYER_ANGLE]
    ld b, a

CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jr z, CheckRight
Left:
    ld b, ANGLE_180DEG

CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jr z, CheckUp
Right:
    ld b, ANGLE_0DEG

CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jr z, CheckDown
Up:
    ld b, ANGLE_90DEG

CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jr z, CheckLeftDown
Down:
    ld b, ANGLE_270DEG

CheckLeftDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN | PADF_LEFT
    jr z, CheckLeftUp
LeftDown:
    ld b, ANGLE_225DEG

CheckLeftUp:
    ld a, [wCurKeys]
    and a, PADF_UP | PADF_LEFT
    jr z, CheckRightDown
LeftUp:
    ld b, ANGLE_135DEG

CheckRightDown:
    ld a, [wCurKeys]
    and a, PADF_RIGHT | PADF_DOWN
    jr z, CheckRightUp
RightDown:
    ld b, ANGLE_315DEG

CheckRightUp:
    ld a, [wCurKeys]
    and a, PADF_RIGHT | PADF_UP
    jr z, CheckEnd
RightUp:
    ld b, ANGLE_45DEG

CheckEnd:
    ld a, b
    ld [PLAYER_ANGLE], a
    
    ld a, [PLAYER_VEL]
    ld b, a
    ; Calcular velocidad
    ; vel_y = sin(ángulo) * velocity
    ; vel_x = cos(ángulo) * velocity
    call PhysicsEngine_computeVelocity

    ; Calcular nueva posición
    ; pos_y = pos_y + vel_y
    ld a, [PLAYER_POS_Y]
    ld h, a
    ld a, [PLAYER_POS_Y + 1]
    ld l, a

    add hl, bc

    ; actualizamos bc con nueva pos
    ld b, h
    ld c, l

    ld a, h
    ld [PLAYER_POS_Y], a
    ld a, l
    ld [PLAYER_POS_Y + 1], a
    
    ; pos_x = pos_x + vel_x
    ld a, [PLAYER_POS_X]
    ld h, a
    ld a, [PLAYER_POS_X + 1]
    ld l, a

    add hl, de

    ; actualizamos de con nueva pos
    ld d, h 
    ld e, l

    ld a, h
    ld [PLAYER_POS_X], a
    ld a, l
    ld [PLAYER_POS_X + 1], a

    ; TODO:
    call PhysicsEngine_check_collision
    
    ; Renderizamos el metasprite
	ld hl, PlayerMetasprite
	call RenderMetasprite
    
    ret


