; El entity manager es el encargado de gestionar
; La creación y destrucción de nuevas entidades.
; Funciona reservando un espacio de memoria fijo.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ENTITY ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   1B FLAGS [7: VALID] [6-5: ENT_TYPE] [4-0: UNUSED]
;   1B MOMENTUM_MAX [0-127]
;   1B MOMENTUM_X   (BIT 7) DIRECTION: 0 LEFT 1 RIGHT | (BIT 6-0): SPEED [0, 127]
;   1B MOMENTUM_Y   (BIT 7) DIRECTION: 0 UP 1 DOWN | (BIT 6-0): SPEED [0, 127]
;   1B MOMENTUM_INC (BIT 7-4) [0, 127] | MOMENTUM_DEC (BIT 3-0) [0, 127]
;   1B HEALTH [0, 255]
;   1B DAMAGE [0, 255]
;   2B ENTITY_DATA_PTR
;   2B SCALED_X
;   2B SCALED_Y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DEF ENT_SZ  EQU 13
DEF ENT_MAX EQU 4

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
DEF ENT_DATA_PTR            EQU 7
DEF ENT_SCALED_X            EQU 9
DEF ENT_SCALED_Y            EQU 11

SECTION "Entity List (EL)", WRAM0
; Puntero al siguiente hueco libre
EntityListFreePtr: DS 2
; Reservamos memoria para la EL.
EntityListStart:: DS ENT_SZ * ENT_MAX

SECTION "Entity Manager (EM)", ROM0
; Como su nombre indica, inicializa los parámetros internos de la EM
InitializeEntityManager::
    ; Inicializar puntero a siguiente espacio vacío.
    ld a, LOW(EntityListStart)
    ld [EntityListFreePtr], a
    ld a, HIGH(EntityListStart)
    ld [EntityListFreePtr + 1], a
    ret

; Inicializa una entidad en la Entity List dada la dirección 
; de inicio de su código en [HL] y el tipo de la entidad en [A]
; devuelve la dirección de la lista asignada a la nueva entidad,
; o FFFF si no hay hueco para asignar una nueva entidad.
Create_Entity::
    ; Validar la nueva entrada e inicializar datos.
    ld a, ENT_FLAGS_VALID
    ld [EntityListFreePtr]
    ret

;; Destruye una entidad dada su inicio en la lista en [HL]
Destroy_Entity::
    ; Invalidar la entrada.
    xor a
    ld [HL], a
    ; Establecer el nuevo hueco como el siguiente.
    ld a, LOW(HL)
    ld [EntityListFreePtr], a
    ld a, HIGH(HL)
    ld [EntityListFreePtr + 1], a
    ret



