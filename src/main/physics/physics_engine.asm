; Motor de físicas encargado del movimiento de las entidades
; y la colisión entre estos y el entorno.

INCLUDE "src/main/utils/constants.inc"

SECTION "Physics Engine Functions", ROM0
; Dado el ángulo y velocidad de un objeto, devuelve las componentes X e Y de dicha velocidad.
;
; IN: A (uint Q8) = Angle
; 
; OUT: BC (signed Q16) = vel_y, DE (signed Q16) = vel_x
;
; DESTRUYE: Todas las variables 
;
; NOTA: vel_y está invertida para funcionar correctamente con la representación en pantalla.
PhysicsEngine_computeVelocity::
    ; vel_y = -sin(angle) = sin(angle + 180º)
    add a, 128
    call sinOfAinDE

    ld b, d
    ld c, e ; BC = -vel_y

    ; vel_x = cos(angle) = sin(angle + 90º)
    ; Tenemos que añadir 64 al ángulo base, pero como ya tiene un añadido de 128, hay que restar 128 + 64 = -64
    ; y nos ahorramos almacenar el ángulo original.
    sub a, 64
    call sinOfAinDE ; DE = vel_x

    ; Escalar velocidades
    sra b
    rr c
    sra b
    rr c

    sra d
    rr e
    sra d
    rr e

    ret 

; Necesitamos las nuevas coordenadas del jugador y el ángulo de movimiento.
; Devolvemos en A si el movimiento es válido en el eje x y en el eje y

; IN: B (uint8) = new SCY, C (uint8) = new SCX
;
; OUT: A (bit 0) = yValid, A (bit 1) = xValid
;
; DESTRUYE: 
PhysicsEngine_check_collision::
    ;Obtener las coordenadas de la esquina superior izquierda del jugador (x, y) = ((scy + player.y), (scx + player.x))
    
    ; b = player_y__inBG
    ld a, PLAYER_POS_Y
    add a, b
    ld b, a

    ; d = player_x_inBG
    ld a, PLAYER_POS_X
    add a, c
    ld d, a

    ; Obtener bloque en el tilemap

    ld a, b
    ld b, 8 ; El tamaño de los bloques es de 8x8 px
    divideAbyB
    ld e, c ; e = bloque.y

    ld a, d
    divideAbyB

    ret

