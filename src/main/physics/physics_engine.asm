; Motor de físicas encargado del movimiento de las entidades
; y la colisión entre estos y el entorno.

INCLUDE "src/main/utils/constants.inc"

SECTION "Physics Engine Variables", WRAM0
PE_VEL: DB
PE_ANGLE: DB

SECTION "Physics Engine Functions", ROM0
; Dado el ángulo y velocidad de un objeto, devuelve las componentes X e Y de dicha velocidad.
;
; IN: B (uint Q8) = Angle, C (uint Q8) = velocity
; 
; OUT: BC (signed Q12.4) = vel_y, DE (signed Q12.4) = vel_x
;
; DESTRUYE: Todas las variables 
;
; NOTA: vel_y está invertida para funcionar correctamente con la representación en pantalla.
PhysicsEngine_computeVelocity::
    ; Si el ángulo es null, no hay movimiento
    ld a, b
    cp ANGLE_NULL
    jr nz, .notNull
    xor a
    ld b, a
    ld c, a
    ld d, a
    ld e, a
    ret

.notNull:
    ; Almacenamos ángulo y velocidad
    ld a, b
    ld [PE_ANGLE], a
    ld a, c
    ld [PE_VEL], a

    ; vel_y = -sin(angle) = sin(angle + 180)
    ld a, b
    add a, 180
    call sinOfAinDE

    ld b, d
    ld c, e ; BC = vel_y

    ; vel_x = cos(angle)
    ld a, [PE_ANGLE]
    add a, 64 ; offset para coseno empleando tabla seno
    call sinOfAinDE ; DE = vel_x

    ; Escalar velocidades
    srl b
    rr c
    srl b
    rr c
    srl b
    rr c
    srl b
    rr c

    srl d
    rr e
    srl d
    rr e
    srl d
    rr e
    srl d
    rr e

    ret 



PhysicsEngine_check_collision::
    ; TODO
    ret

