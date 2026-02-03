; El entity manager es el encargado de gestionar
; La creación y destrucción de nuevas entidades,
; y se encarga de disparar la actualización
; de la lógica de las entidades en cada ciclo.

; Funciona reservando un espacio de memoria fijo.

include "src/main/utils/constants.inc"

SECTION "Entity List", WRAM0
; Número de huecos libres en la lista de entidades.
EntityListRemaining: DB
;Dirección 2B en little endian
ENT_LIST_PTR_LB: DB
ENT_LIST_PTR_HB: DB
; Reservamos memoria para la EL.
EntityListStart:: DS ENT_SZ * ENT_LIST_MAX
EntityListEnd::

SECTION "Entity Manager", ROM0
; Inicializa el gestor de entidades.
EntityManager_func_initialize::
    ld a, ENT_LIST_MAX
    ld [EntityListRemaining], a

    ld a, LOW(EntityListStart)
    ld [ENT_LIST_PTR_LB], a
    ld a, HIGH(EntityListStart)
    ld [ENT_LIST_PTR_HB], a
    ret

; Intenta inicializar una entidad en la tabla de entidades
; dada la dirección de memoria del código que inicializa
; sus atributos.
:
; create_entity(hl = entity* init_data) returns none;
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

    ; RET implícito desde dicho código.


    
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

; Actualiza la lógica de todas las entidades con 
;entrada en la lista de entidades
;
; update() returns none;
;
EntityManager_update_logic::
    ld hl, EntityListStart
    ld b, ENT_LIST_MAX

    ; Actualizar la lógica del jugador, que siempre es la primera entidad en la lista.
    call ent_player_func_update_logic
    
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
    jr. loop

.checkBomb:
    cp ENT_TYPE_BOMB
    jr nz, .isPlayer
    ; TODO: Implementar lógica enemigo
    jr .loop

.isPlayer:
    call ent_player_update_logic
    jr .loop



; Vuelca a los registros reales de OAM y LCD los valores actualizados.
;
; dump_logic() returns none;
;
; Solo debe ser llamada durante VBlank.
EntityManager_dump_logic::
    ; Actualización del BGScroll durante vblank
	ld a, [wBackgroundScroll_Y_real]
	ld [rSCY], a
	ld a, [wBackgroundScroll_X_real]
	ld [rSCX], a

    ; Actualización de la OAM
    ld a, HIGH(wShadowOAM)
	call hOAMDMA

	ret


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