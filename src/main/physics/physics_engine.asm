; Motor de físicas encargado del movimiento de las entidades
; y la colisión entre estos y el entorno.

INCLUDE "src/main/utils/constants.inc"

SECTION "Physics Engine Functions", ROM0
; Dado el ángulo y velocidad de un objeto, devuelve las componentes X e Y de dicha velocidad.
;
; IN: A(B) (uint Q8) = Angle
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

; IN: Las coordenadas de la esquina superior izquierda del jugador (x, y) = ((scy + player.y), (scx + player.x))
PhysicsEngine_check_collision::
    ; TODO
    ret

