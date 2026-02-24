INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

; Player Constants
DEF ENT_PLAYER_INIT_VEL_MAX EQU 60
DEF ENT_PLAYER_INIT_HEALTH  EQU 20
DEF ENT_PLAYER_INIT_DAMAGE  EQU 5
DEF ENT_PLAYER_INIT_VEL_INC      EQU 16


SECTION "Player Variables", WRAM0
ENT_PLAYER_VEL:: DB
ENT_PLAYER_VEL_MAX:: DB
ENT_PLAYER_VEL_INC:: DB
ENT_PLAYER_ANGLE:: DB
ENT_PLAYER_X:: DW   ;Q12.4
ENT_PLAYER_Y:: DW   ;Q12.4
ENT_PLAYER_HEALTH:: DB
ENT_PLAYER_DAMAGE:: DB
ENT_PLAYER_SHOOTING_FRECUENCY:: DB
ENT_PLAYER_BULLET_VELOCITY:: DB

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
    ld [ENT_PLAYER_VEL], a

    ld [ENT_PLAYER_ANGLE], a

    ld [ENT_PLAYER_X], a
    ld [ENT_PLAYER_X + 1], a

    ld [ENT_PLAYER_Y], a
    ld [ENT_PLAYER_Y + 1], a

    ld a, [ENT_PLAYER_INIT_VEL_MAX]
    ld [ENT_PLAYER_VEL_MAX], a

    ld a, [ENT_PLAYER_INIT_VEL_INC]
    ld [ENT_PLAYER_VEL_INC], a

    ret



Player_update_logic::

    ; Obtener ángulo
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
    ; Calculamos velocidad en cada eje en base al ángulo de movimiento.
    ; TODO
    ld a, b
    call sinOfAinDE
      
    ld h, d
    ld l, e ; HL = SIN(A)

    ld a, [ENT_PLAYER_VEL]

    add a, 64 ; offset coseno
    call sinOfAinDE ; DE = COS(A)

    ; Aañdimos a shadowOAM el metasprite
    ld a, [ENT_PLAYER_Y]
	ld b, a
    ld a, [ENT_PLAYER_Y + 1]
	ld c, a
    ld a, [ENT_PLAYER_X]
	ld d, a
	ld a, [ENT_PLAYER_X+1]
    ld e, a
	ld hl, PlayerMetasprite
	call RenderMetasprite
    
    ret


