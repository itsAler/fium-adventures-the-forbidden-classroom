
include "src/main/utils/hardware.inc"

SECTION "OAM DMA", HRAM
hOAMDMA::
    ds DMARoutineEnd - DMARoutine ; Reservamos espacio para copiar la rutina DMA

SECTION "SpriteVariables", WRAM0

wLastOAMAddress:: dw
wSpritesUsed:: db
wHelperValue::db

SECTION "Sprites", ROM0

; La pantalla debe estar apagada para acceder de manera
; segura a la OAM.
ClearOAM::
    xor a
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ret

SECTION "OAM DMA routine", ROM0

; LLamar una vez al inicio del juego. Imprescindible para el funcionamiento
; de la función de transferencia por DMA de la shadowOAM a OAM.
; https://gbdev.gg8.se/wiki/articles/OAM_DMA_tutorial
CopyDMARoutineToHRAM:
    ld hl, DMARoutine
    ld b, DMARoutineEnd - DMARoutine ; Número de bytes a copiar
    ld c, LOW(hOAMDMA) ; Low byte de la dirección de destino. en HRAM, etiqueta fija.
.copy
    ld a, [hli]
    inc c
    ; ldh automáticamente asigna FF en el high byte, siendo c el lowbyte 
    ; forma la dir. completa en HRAM. Ahorrando una variable doble, y 
    ; convirtiendo esta línea de código en un "optimiseision paradais"
    ldh [c], a 
    dec b
    jr nz, .copy
    ret

; La rutina de transferencia de RAM a OAM.
DMARoutine:
    ; Escribir en esta dirección inicia una transferencia DMA a la dirección
    ; aa00, siendo aa un byte. Si a = 8A, entonces rDMA=8A00.
    ldh [rDMA], a 

    ; Esperamos 160 nanosegundos con la siguiente función:
    ld a, 40
.wait
    dec a
    jr  nz, .wait
    ret
DMARoutineEnd:
