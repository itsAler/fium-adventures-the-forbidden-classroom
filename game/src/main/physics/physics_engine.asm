; Motor de físicas encargado del movimiento de las entidades
; y la colisión entre estos y el entorno.

SECTION "Physics Engine Functions", ROM0
; Dado el ángulo y velocidad de un objeto, devuelve las componentes X e Y de dicha velocidad.
;
; IN: B = Angle, C = velocity
; 
; OUT: BC = Q12.4 vel_y, DE = Q12.4 vel_x
PhysicsEngine_computeVelocity::
    push bc ; Almacenamos ángulo y velocidad para vel_x

    ; vel_y = sin(angle) * velocity
    ld a, b
    call sinOfAinDE

    ld a, c
    call Mul16x8 ; HL = vel_y

    ld b, h ; BC = vel_y
    ld c, l

    pop hl ; H = angle, L = velocity

    ; vel_x = cos(angle) * velocity
    ld a, h
    add a, 64 ; offset para coseno empleando tabla seno
    call sinOfAinDE

    ld a, l
    call Mul16x8 ; HL = vel_x

    ld d, h ; DE = vel_x
    ld e, l

    ret 



PhysicsEngine_check_collision::
    ret

