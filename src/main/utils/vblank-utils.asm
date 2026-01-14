INCLUDE "src/main/utils/hardware.inc"

SECTION "VBlankVariables", WRAM0

wVBlankCount:: db 


SECTION "VBlankFunctions", ROM0

WaitForOneVBlankFunction::
    ld a,1
    ld [wVBlankCount],a

; Espera a vBlank las veces especificadas en la variable wVBlankCount
WaitForVBlankFunction::
    ; Guardar en pila BC y cargar contador de vBlank
    push bc

    ld a, [wVBlankCount]
    ld b, a

WaitForVBlankFunction_Loop:
    ; En bucle hasta que línea LCD == 144 (Vblank)
	ld a, [rLY]
	cp 144 ; C set if A < 144
	jp c, WaitForVBlankFunction_Loop

    ; Decrementar contador y salir del bucle si es 0
    ld a, b 
    sub a, 1
    ld b, a
    jp z, WaitForVBlankFunction_End
    ; Volver a realizar el bucle de espera a vBlank
    jp WaitForVBlankFunction_Loop

WaitForVBlankFunction_End:
    pop bc
    ret
