; El entity manager es el encargado de gestionar
; La creación y destrucción de nuevas entidades,
; y se encarga de disparar la actualización
; de la lógica de las entidades en cada ciclo.

; Funciona reservando un espacio de memoria fijo.

include "src/main/utils/constants.inc"

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

SECTION "Entity Manager temp variables", WRAM0
ENT_OLD_MOMENTUM_X:: DB
ENT_OLD_MOMENTUM_Y:: DB

SECTION "Entity List variables", WRAM0
; Número de huecos libres en la lista de entidades.
EntityListRemaining: DB
;Dirección 2B en little endian
ENT_LIST_PTR_LB: DB
ENT_LIST_PTR_HB: DB
; Reservamos memoria para la EL.
EntityListStart: DS ENT_SZ * ENT_LIST_MAX
EntityListEnd:

SECTION "Entity Manager", ROM0
; Inicializa el gestor de entidades.
EntityManager_init::
    ld a, ENT_LIST_MAX
    ld [EntityListRemaining], a

    ld a, LOW(EntityListStart)
    ld [ENT_LIST_PTR_LB], a
    ld a, HIGH(EntityListStart)
    ld [ENT_LIST_PTR_HB], a
    ret
; Inicializa una entidad en la tabla de entidades.
;
; No se asegura la inicialización si la tabla está llena.
;
; create_entity(hl = ent_init_data* data) returns none;
;
; Destruye: a, b, hl, de.
EntityManager_add_entity::
    ; Comprobar si quedan entradas libres
    ld a, [EntityListRemaining]
    cp 0
    ret z

    ; Decrementar número de entradas libres
    dec a
    ld [EntityListRemaining], a

    ; Obtener entrada de la tabla donde almacenar la nueva entidad
    ld a, [ENT_LIST_PTR_HB]
    ld b, a
    ld a, [ENT_LIST_PTR_LB]
    ld c, a

    ; Buscar de manera circular y dejar en DE
    ; la siguiente entrada libre, si existiera.
    ld a, [EntityListRemaining]
    cp 0
    jr z, .isFull

    ld a, [ENT_LIST_PTR_HB]
    ld d, a
    ld a, [ENT_LIST_PTR_LB]
    ld e, a

.searchLoop:
    ld a, ENT_SZ
    add e
    ld e, a
    ld a, d
    adc 0 
    ld d, a

    ; Comprobar si la nueva entrada está en los límites de la lista
    ; HL =< EntityListEnd --> H < HIGH(EntityListEnd) OR 
    ; (H = HIGH(EntityListEnd) AND L =< LOW(EntityListEnd))
    ld a, HIGH(EntityListEnd)
    cp d
    jr c, .isLess
    jr nz, .isGreather

    ld a, LOW(EntityListEnd)
    cp e
    jr nc, .isLess

.isGreather:
    ld de, EntityListStart

.isLess:
    ; Comprobar si el hueco está disponible  
    ld a, [de]
    and ENT_FLAG_STATUS
    cp ENT_STATUS_VALID
    jr z, .searchLoop

    ; Guardar la dirección de la nueva entrada sin usar
    ld a, d
    ld [ENT_LIST_PTR_HB], a
    ld a, e
    ld [ENT_LIST_PTR_LB], a

.isFull:
    ; Inicializar la nueva entrada.
    jp hl ; Dirección con el código de inicialización de la entidad

    ; RET implícito desde ent_init.


    
; Invalida todas las entradas de la lista de entidades.
;
; clear_all() returns none;
;
; Destruye: a, b, hl
EntityManager_clear_all::

    ld b, ENT_LIST_MAX 
    ld hl, EntityListStart 

    ; Resetear el puntero a la siguiente entrada libre.
    ld a, h
    ld [ENT_LIST_PTR_HB], a
    ld a, l
    ld [ENT_LIST_PTR_LB], a

.loop:
    ld [hl], ENT_STATUS_INVALID
    call get_next

    dec b 
    cp b 
    ret z 

    jr .loop

; Actualiza la lógica de todas las entidades 
; presentes en la lista de entidades
;
; update() returns none;
;
EntityManager_update_logic::
    ld hl, EntityListStart
    ld b, ENT_LIST_MAX

    ; TODO Arreglar lista sin jugador
    
.loop:
    call get_next

    dec b
    xor a
    cp b
    ret nc
    
    ; Comprobar si la entrada está en uso.
    ld a, [hl]
    and ENT_FLAG_STATUS
    cp ENT_STATUS_VALID
    jr nz, .loop

    ; Comprobar el tipo de la entidad.
    ; Saltar a la dirección de memoria de comienzo del algoritmo implementa su lógica.
    ld a, [hl]
    and ENT_FLAG_TYPE
    ; El orden de comprobación que da el menor 
    ; número de fallos, y que por tanto evita comprobaciones es: 
    ; enemigos > objetos interactuables > bomb > player.

    cp ENT_TYPE_ENEMY
    jr nz, .checkChest
    ; TODO: Implementar lógica enemigo
    jr .loop

.checkChest:
    cp ENT_TYPE_CHEST
    jr nz, .checkBomb
    ; TODO implementar lógica cofre
    jr .loop

.checkBomb:
    cp ENT_TYPE_BOMB
    ; TODO: Implementar lógica enemigo
    jr .loop


    
; Obtiene el comienzo del siguiente elemento de la lista
;
; get_next(hl = entity_table* previous) returns hl;
;
; Destruye; a, hl.
get_next:
    ld a, ENT_SZ
    add l
    ld l, a
    ld a, h
    adc 0 
    ld h, l
    
    ret