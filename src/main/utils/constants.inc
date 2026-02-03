include "src/main/utils/hardware.inc"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ENTITY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   1B FLAGS [7: STATUS] [6-3: ENT_TYPE] [2-0: UNUSED]
;       STATUS:     Estado actual de la entrada (inválida, válida)
;       ENT_TYPE:   Tipo de la entidad (jugador, enemigo...)
;   1B MOMENTUM_MAX [0-127]
;   1B MOMENTUM_INC_DEC [7-4: INCREMENT] [3-0: DECREMENT] 
;   1B HEALTH [0, 255]
;   1B DAMAGE [0, 255]
;   1B MOMENTUM_X   (BIT 7) DIRECTION: 0 LEFT 1 RIGHT | (BIT 6-0): SPEED [0, 127]
;   1B MOMENTUM_Y   (BIT 7) DIRECTION: 0 UP 1 DOWN | (BIT 6-0): SPEED [0, 127]
;   2B SCALED_X [0, 65535]
;   2B SCALED_Y [0, 65535]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEF ENT_SZ  EQU 11
DEF ENT_LIST_MAX EQU 4 ; Límite actual de 256 entidades

; Atributos y máscaras
DEF ENT_FLAG_STATUS         EQU %10000000
DEF ENT_STATUS_VALID        EQU %10000000
DEF ENT_STATUS_INVALID      EQU %00000000
DEF ENT_FLAG_TYPE           EQU %01111000
DEF ENT_TYPE_PLAYER         EQU %00000000
DEF ENT_TYPE_CHEST          EQU %00001000
DEF ENT_TYPE_ENEMY          EQU %00010000
DEF ENT_TYPE_BOMB           EQU %00011000
DEF ENT_MOMENTUM_INC        EQU %11110000 ; Aplicar 4 desplazamientos hacia la derecha para obtener valor real.
DEF ENT_MOMENTUM_DEC        EQU %00001111
DEF ENT_MOMENTUM_INC_DEC    EQU %01111111
DEF ENT_MOMENTUM_DIR        EQU %10000000
DEF ENT_DIR_LEFT            EQU %00000000
DEF ENT_DIR_RIGHT           EQU %10000000
DEF ENT_DIR_UP              EQU %00000000
DEF ENT_DIR_DOWN            EQU %10000000

DEF ENT_PLAYER_INIT_MOMENTUM_MAX        EQU 60
DEF ENT_PLAYER_INIT_MOMENTUM_INC_DEC    EQU %11110001
DEF ENT_PLAYER_INIT_HEALTH              EQU 20
DEF ENT_PLAYER_INIT_DAMAGE              EQU 5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEF MAX_ENEMY_COUNT EQU 10
DEF MAX_BULLET_COUNT EQU 5

DEF ENEMY_SPAWN_DELAY_MAX EQU 70

; from https://rgbds.gbdev.io/docs/v0.6.1/rgbasm.5#EXPRESSIONS
; The RS group of commands is a handy way of defining structure offsets:
RSRESET
DEF metasprite_y                RB   1
DEF metasprite_x                RB   1
DEF metasprite_tile             RB   1
DEF metasprite_flag             RB   1
DEF METASPRITE_BYTES_COUNT      RB   0

; from https://rgbds.gbdev.io/docs/v0.6.1/rgbasm.5#EXPRESSIONS
; The RS group of commands is a handy way of defining structure offsets:
RSRESET
DEF enemy_activeByte            RB   1
DEF enemy_xByte                 RB   1
DEF enemy_yLowByte              RB   1
DEF enemy_yHighByte             RB   1
DEF enemy_speedByte             RB   1
DEF enemy_healthByte            RB   1
DEF PER_ENEMY_BYTES_COUNT       RB   0

; ANCHOR: bullet-offset-constants
; from https://rgbds.gbdev.io/docs/v0.6.1/rgbasm.5#EXPRESSIONS
; The RS group of commands is a handy way of defining structure offsets:
RSRESET
DEF bullet_activeByte            RB   1
DEF bullet_xByte                 RB   1
DEF bullet_yLowByte              RB   1
DEF bullet_yHighByte             RB   1
DEF PER_BULLET_BYTES_COUNT       RB   0
; ANCHOR_END: bullet-offset-constants

; ANCHOR: sprite-vram-constants
RSRESET
DEF spriteTilesStart            RB _VRAM
DEF PLAYER_TILES_START          RB 4*16
DEF ENEMY_TILES_START           RB 4*16
DEF BULLET_TILES_START          RB 0
; ANCHOR_END: sprite-vram-constants


DEF ENEMY_MOVE_SPEED EQU 11
DEF BULLET_MOVE_SPEED EQU 20

DEF PLAYER_MOVE_SPEED EQU 15
DEF PADDLE_Y_POSITION EQU 136
