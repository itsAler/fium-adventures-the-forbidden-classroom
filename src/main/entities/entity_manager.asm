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

DEF ENT_FLAG_VALID  EQU %10000000
DEF ENT_VALID       EQU %10000000
DEF ENT_INVALID     EQU %00000000
DEF ENT_FLAG_TYPE   EQU %01100000
DEF ENT_TYPE_PLAYER EQU %00000000
DEF ENT_TYPE_CHEST  EQU %00100000
DEF ENT_TYPE_ENEMY  EQU %01000000
DEF ENT_TYPE_BOMB   EQU %01100000

DEF ENT_FLAGS               EQU 0
DEF ENT_MOMENTUM_MAX        EQU 1
DEF ENT_MOMENTUM_X          EQU 2
DEF ENT_MOMENTUM_Y          EQU 3
DEF ENT_MOMENTUM_INC_DEC    EQU 4
DEF ENT_HEALTH              EQU 5
DEF ENT_DAMAGE              EQU 6
; Codificado en Little Endian
DEF ENT_METADATA_PTR        EQU 7
DEF ENT_SCALED_X            EQU 9
DEF ENT_SCALED_Y            EQU 11

SECTION "Entity List", WRAM0
; Número de huecos libres en la lista de entidades.
EntityListRemaining: DB
;Dirección 2B en little endian al siguiente hueco libre en la lista de entidades.
ptr_next_free: DW
; Reservamos memoria para la EL.
EntityListStart:: DS ENT_SZ * ENT_LIST_MAX
EntityListEnd::

SECTION "Entity Manager", ROM0
; Inicializa el gestor de entidades.
EntityManager_Initialize::
    ld a, ENT_LIST_MAX
    ld [EntityListRemaining], a

    ld a, LOW(EntityListStart)
    ld [ptr_next_free], a
    ld a, HIGH(EntityListStart)
    ld [ptr_next_free + 1], a
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
    ret z

    ; Decrementar contador
    dec a
    ld [EntityListRemaining], a

    ; Inicializar la nueva entrada.
    ld a, ENT_VALID
    or a, b
    ld [ptr_next_free + ENT_FLAGS], a

    ld a, LOW(HL)
    ld [ptr_next_free + ENT_METADATA_PTR], a
    ld a, HIGH(HL)
    ld [ptr_next_free + 1 + ENT_METADATA_PTR], a

    ; Obtener la siguiente entrada libre, si es que quedan huecos
    ld a, [EntityListRemaining]
    cp 0
    ret z

    push hl

    ; Buscar de manera circular en la lista
    .searchLoop:
    ld a, l
    add ENT_SZ
    ld l, a
    ld a, h
    adc 0
    ld h, a


    ; HL =< EntityListEnd implica
    ; H < HIGH(EntityListEnd) OR (H = HIGH(EntityListEnd) AND L =< LOW(EntityListEnd) )

    ld a, HIGH(EntityListEnd)
    cp h
    jr c, .isLess
    jr nz, .isGreatherMSB

    ld a, LOW(EntityListEnd)
    cp l
    jr nc, .isLess

    .isGreather:
    ld hl, EntityListStart

    .isLess:
    ; Comprobar si el hueco está disponible  
    ld a, [hl + ENT_FLAGS]
    and ENT_FLAG_VALID
    cp ENT_INVALID
    jr nz, .searchLoop

    ; Guardar el hueco libre como el siguiente a utilizar
    ld a, l
    ld [ptr_next_free], a
    ld a, h
    ld [ptr_next_free + 1] a

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
    ld [ptr_next_free], a
    ld a, HIGH(HL)
    ld [ptr_next_free + 1], a    
    ret

; Invalida todas las entradas de la lista de entidades.
;
; clear_all() returns none;
;
; Destruye: a, b, hl, de
EntityManager_func_clear_all::
    ld b, ENT_LIST_MAX 
    ld hl, EntityListStart 
    xor a
    ld d, a 
    ld e, ENT_SZ

    .loop:
    ld [hl], a
    add hl, de 

    dec b 
    cp b 
    ret z 

    jr .loop


