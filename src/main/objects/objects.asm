; Se definen en ROM los datos de los distintos jugadores y enemigos
; que no cambian durante la ejecución del juego.

; Actualmente los sprites solo son de 16x16, más adelante puede generalizarse.

; Añadir aquí algoritmo de movimiento??

SECTION "OBJECTS", ROM0
;;; PLAYER
playerWeight:: 
playerIdle:: INCBIN "src/generated/sprites/player.2bpp"
playerIdleEnd::

playerMove1::
playerMove1End::

;;; BABOSA
slugIdle::    
    DB $00,$00,$00,$00,$01,$01,$04,$05
    DB $00,$7F,$7E,$81,$00,$FE,$00,$00
slugIdleEnd::

slugMove::    
    DB $00,$00,$00,$00,$01,$31,$34,$4D
    DB $78,$87,$66,$99,$00,$EE,$00,$00
slugMoveEnd::