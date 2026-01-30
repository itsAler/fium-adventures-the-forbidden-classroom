; El entity manager es el encargado de gestionar
; La creación y destrucción de nuevas entidades.
; Funciona reservando un espacio de memoria fijo.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ENTITY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   1B FLAGS [7: VALID] [6-5: ENT_TYPE] [4-0: EFECTS]
;   1B MOMENTUM_MAX [0-127]
;   1B MOMENTUM_X   (BIT 7) DIRECTION: 0 LEFT 1 RIGHT | (BIT 6-0): SPEED [0, 127]
;   1B MOMENTUM_Y   (BIT 7) DIRECTION: 0 UP 1 DOWN | (BIT 6-0): SPEED [0, 127]
;   1B MOMENTUM_INC (BIT 7-4) [0, 127] | MOMENTUM_DEC (BIT 3-0) [0, 127]
;   1B HEALTH [0, 255]
;   1B DAMAGE [0, 255]
;   2B ENTITY_METADATA
;   2B SCALED_X
;   2B SCALED_Y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEF ENT_SZ  EQU 13
DEF ENT_LIST_MAX EQU 4 ; Límite actual de 256 entidades

DEF ENT_FLAGS_VALID EQU %10000000
DEF ENT_VALID       EQU %10000000
DEF ENT_INVALID     EQU %00000000
DEF ENT_FLAGS_TYPE  EQU %01100000
DEF ENT_TYPE_PLAYER EQU %00000000
DEF ENT_TYPE_CHEST  EQU %00100000
DEF ENT_TYPE_ENEMY  EQU %01000000
DEF ENT_TYPE_BOMB   EQU %01100000

DEF ENT_MOMENTUM_MAX        EQU 1
DEF ENT_MOMENTUM_X          EQU 2
DEF ENT_MOMENTUM_Y          EQU 3
DEF ENT_MOMENTUM_INC_DEC    EQU 4
DEF ENT_HEALTH              EQU 5
DEF ENT_DAMAGE              EQU 6
DEF ENT_METADATA            EQU 7
DEF ENT_SCALED_X            EQU 9
DEF ENT_SCALED_Y            EQU 11

SECTION "Entity List", WRAM0
; Número de huecos libres en la lista de entidades
EntityListRemaining: DB
; Siguiente hueco libre
EntityListFreePtr: DW
; Reservamos memoria para la EL.
EntityListStart:: DS ENT_SZ * ENT_LIST_MAX

SECTION "Entity Manager", ROM0
; Inicializa el gestor de entidades.
EntityManager_Initialize::
    ld a, ENT_LIST_MAX
    ld [EntityListRemaining], a

    ld a, LOW(EntityListStart)
    ld [EntityListFreePtr], a
    ld a, HIGH(EntityListStart)
    ld [EntityListFreePtr + 1], a
    ret

; Inicializa una entidad.
;
; create_entity(hl = entity_metadata* data, a = ENT_TYPE) returns none;
;
; Destruye: a, b.
EntityManager_Create_Entity::
    ld b, a
    ; Comprobar si quedan entradas libres
    ld a, [EntityListRemaining]
    cp 0
    jr z, .isFull

    dec a
    ld [EntityListRemaining], a

    ; Inicializar la nueva entrada.
    ld a, ENT_VALID
    or a, b
    ld [EntityListFreePtr], a

    ld a, LOW(HL)
    ld [EntityListFreePtr + ENT_METADATA], a
    ld a, HIGH(HL)
    ld [EntityListFreePtr + ENT_METADATA + 1], a

.isFull:
    ret

; Destruye una entidad
;
; destroy_entity( hl = entity* e) returns none;
EntityManager_Destroy_Entity::
    xor a
    ld [HL], a

    ld a, [EntityListRemaining]
    inc a
    ld [EntityListRemaining], a

    ; Establecer el nuevo hueco como el siguiente.
    ld a, LOW(HL)
    ld [EntityListFreePtr], a
    ld a, HIGH(HL)
    ld [EntityListFreePtr + 1], a    
    ret

; Invalida todas las entradas de la lista de entidades.
;
; Destruye: a, b, hl
EntityManager_Clear_All::
    ld b, ENT_LIST_MAX

    ld h, HIGH(EntityListStart)
    ld l, LOW(EntityListStart)

    xor d
    ld e, ENT_SZ

    xor a

.entityRemaining:
    ld [hl], a
    dec b
    add hl, de
    cp b
    jr nz, .entityRemaining
    ret



