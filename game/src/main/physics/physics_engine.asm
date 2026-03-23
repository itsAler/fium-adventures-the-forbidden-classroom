; Motor de físicas encargado del movimiento de las entidades
; y la colisión entre estos y el entorno.

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
    ; Almacenamos ángulo y velocidad
    ld a, b
    ld [PE_ANGLE], a
    ld a, c
    ld [PE_VEL], a

    ; vel_y = sin(angle) * velocity
    ld a, b
    call sinOfAinDE

    ; Negar vel_y
    xor a
    sub e
    ld c, a
    ld a, 0
    sbc a, d
    ld b, a         ; BC = -vel_y

    ; vel_x = cos(angle) * velocity
    ld a, [PE_ANGLE]
    add a, 64 ; offset para coseno empleando tabla seno
    call sinOfAinDE ; DE = vel_x

    ; Tratamos la velocidad como un sumando a los ejes y no como un multiplicador
    ; Tener cuidado con el signo: a un valor negativo, le corresponde un incremento negativo de la velocidad

    ; Eje X
    ; Comprobar si es negativo y añadir velocidad
    ld a, [PE_VEL] 

    bit 3, d
    jr z, .positive_x

    cpl
    inc a

.positive_x:
    add a, e
    ld e, a
    ld a, d
    adc a, 0
    ld d, a


    ; Eje Y
    ld a, [PE_VEL] 

    bit 3, b
    jr z, .positive_y

    cpl
    inc a

.positive_y:
    add a, c
    ld c, a
    ld a, b
    adc a, 0
    ld b, a

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

