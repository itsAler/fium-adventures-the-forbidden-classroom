; Motor de físicas encargado del movimiento de las entidades
; y la colisión entre estos y el entorno.

SECTION "Physics Engine Variables", WRAM0
PE_VEL: DB
PE_ANGLE: DB

SECTION "Physics Engine Functions", ROM0
; Dado el ángulo y velocidad de un objeto, devuelve las componentes X e Y de dicha velocidad.
;
; IN: B = Angle, C = velocity
; 
; OUT: BC = Q12.4 vel_y, DE = Q12.4 vel_x
PhysicsEngine_computeVelocity::
    ; Almacenamos ángulo y velocidad
    ld a, b
    ld [PE_ANGLE], a
    ld a, c
    ld [PE_VEL], a

    ; vel_y = sin(angle) * velocity
    ld a, b
    call sinOfAinDE
; $0B57
    ld b, e ; BC = vel_y 
    ld c, d

    ; vel_x = cos(angle) * velocity
    ld a, [PE_ANGLE]
    add a, 64 ; offset para coseno empleando tabla seno
    call sinOfAinDE

    ld h, d
    ld d, e ; DE = vel_x
    ld e, h

    ret 



PhysicsEngine_check_collision::
    ret

