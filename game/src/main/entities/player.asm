INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"
INCLUDE "src/main/physics/trigonometry.asm"

DEF ENT_PLAYER_INIT_VEL_MAX EQU 60
DEF ENT_PLAYER_INIT_HEALTH  EQU 20
DEF ENT_PLAYER_INIT_DAMAGE  EQU 5
DEF ENT_PLAYER_VEL_INC      EQU 16


SECTION "Player Variables", WRAM0
ENT_PLAYER_VEL:: DB
ENT_PLAYER_VEL_MAX:: DB
ENT_PLAYER_VEL_INC:: DB
ENT_PLAYER_ANGLE:: DB
ENT_PLAYER_X:: DW   ;Q12.4
ENT_PLAYER_Y:: DW   ;Q12.4
ENT_PLAYER_INIT_HEALTH:: DB
ENT_PLAYER_INIT_DAMAGE:: DB
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
ent_player_init::
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

    ; Inicializamos los atributos del jugador
    xor a
    ld [ENT_PLAYER_VEL]

    ld [ENT_PLAYER_ANGLE]

    ld [ENT_PLAYER_X]
    ld [ENT_PLAYER_X + 1]

    ld [ENT_PLAYER_Y]
    ld [ENT_PLAYER_Y + 1]

    ld a, [ENT_PLAYER_INIT_VEL_MAX]
    ld [ENT_PLAYER_VEL_MAX]

    ld a, [ENT_PLAYER_INIT_VEL_INC]
    ld [ENT_PLAYER_VEL_INC]

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
    ld a, b
    call sinOfAinDE

    ENT_PLAYER_VEL
    
    ld hl, de ; HL SIN(A)

    ld a, [ENT_PLAYER_VEL]

    add a, 64 ; offset coseno
    call sinOfAinDE ; DE COS(A)
    
    
    ret


