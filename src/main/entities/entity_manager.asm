; El entity manager es el encargado de gestionar
; La creación y destrucción de nuevas entidades.
; Funciona reservando un espacio de memoria fijo.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ENTITY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   1B FLAGS [7: STATUS] [6-3: ENT_TYPE] [2-0: UNUSED]
;       STATUS:     Estado actual de la entrada (inválida, válida)
;       ENT_TYPE:   Tipo de la entidad (jugador, enemigo...)
;       INITIALIZED: La entidad acaba de crearse o ha sido colocada ya en el mundo.
;       EFECTS:      Efecto aplicado sobre la entidad (daño, fuego, hielo...)
;   1B MOMENTUM_MAX [0-127]
;   1B MOMENTUM_X   (BIT 7) DIRECTION: 0 LEFT 1 RIGHT | (BIT 6-0): SPEED [0, 127]
;   1B MOMENTUM_Y   (BIT 7) DIRECTION: 0 UP 1 DOWN | (BIT 6-0): SPEED [0, 127]
;   1B MOMENTUM_INC (BIT 7-4) [0, 127] | MOMENTUM_DEC (BIT 3-0) [0, 127]
;   1B HEALTH [0, 255]
;   1B DAMAGE [0, 255]
;   2B SCALED_X
;   2B SCALED_Y
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
; Offsets de cada atributo
DEF ENT_FLAGS               EQU 0
DEF ENT_MOMENTUM_MAX        EQU 1
DEF ENT_MOMENTUM_X          EQU 2
DEF ENT_MOMENTUM_Y          EQU 3
DEF ENT_MOMENTUM_INC_DEC    EQU 4
DEF ENT_HEALTH              EQU 5
DEF ENT_DAMAGE              EQU 6
DEF ENT_SCALED_X            EQU 7
DEF ENT_SCALED_Y            EQU 9

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
EntityManager_func_initialize::
    ld a, ENT_LIST_MAX
    ld [EntityListRemaining], a

    ld a, LOW(EntityListStart)
    ld [ptr_next_free], a
    ld a, HIGH(EntityListStart)
    ld [ptr_next_free + 1], a
    ret

; Inicializa una entidad.
;
; create_entity(a = ENT_TYPE) returns none;
;
; Destruye: a, b, hl.
EntityManager_func_create_entity::
    ld b, a
    ; Comprobar si quedan entradas libres
    ld a, [EntityListRemaining]
    cp 0
    ret z

    ; Decrementar contador
    dec a
    ld [EntityListRemaining], a

    ; Inicializar la nueva entrada.
    ld a, ENT_STATUS_VALID
    or b ; ENT_TYPE
    ld [ptr_next_free + ENT_FLAGS], a

    ; Obtener la siguiente entrada libre, si es que quedan huecos
    ld a, [EntityListRemaining]
    cp 0
    ret z

    ; Buscar de manera circular en la lista
.searchLoop:
    call get_next
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
    and ENT_FLAG_STATUS
    cp ENT_STATUS_VALID
    jr z, .searchLoop

    ; Guardar el hueco libre como el siguiente a utilizar
    ld a, l
    ld [ptr_next_free], a
    ld a, h
    ld [ptr_next_free + 1] a

    ret

; Destruye una entidad
;
; destroy_entity( hl = entity* e) returns none;
EntityManager_func_destroy_entity::
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
; Destruye: a, b, hl
EntityManager_func_clear_all::

    ld b, ENT_LIST_MAX 
    ld hl, EntityListStart 

.loop:
    ld [hl], ENT_STATUS_INVALID
    call get_next

    dec b 
    cp b 
    ret z 

    jr .loop

; Actualiza la lógica de todas las entidades con 
;entrada en la lista de entidades
;
; update() returns none;
;
EntityManager_func_update::
    ld hl, EntityListStart
    ld b, ENT_LIST_MAX

    ; Actualizar la lógica del jugador, que siempre es la primera entidad en la lista
    
.loop:
    call get_next

    dec b
    xor a
    cp b
    jr nc, .end:
    
    ld a, [hl + ENT_FLAGS]
    and ENT_FLAG_STATUS
    cp ENT_STATUS_VALID
    jr nz, .loop

    ; Comprobar el tiempo de la entidad.
    ; Saltar a la dirección de memoria de comienzo de la actualización de su lógica.
    
    ld a, [hl + ENT_FLAGS]
    and ENT_FLAG_TYPE

    cp, ENT_TYPE_BOMB
    jr nz, .checkEnemy
    ; Lógica de la bomba
    jr .loop

.checkEnemy:
    cp, ENT_TYPE_ENEMY
    jr nz, .checkChest
    ; Lógica del enemigo
    jr .loop

.checkChest
    cp, ENT_TYPE_CHEST
    ; Lógica del cofre
    jr nz, .loop

.end:
    ret


; Obtiene el comienzo del siguiente elemento de la lista
;
; get_next(hl = entity* previous) returns hl;
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