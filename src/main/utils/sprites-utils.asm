
include "src/main/utils/hardware.inc"

SECTION "OAM DMA", HRAM
; Copia datos de la shadowOAM a la OAM. Este proceso toma menos tiempo
; que hacerlo con ld mediante la CPU.
;
; El registro A debe contener el highbyte de la dirección de comienzo.
;
; La PPU debe encontrarse en Modo 1 (Vblank).
;
; Source:      $XX00-$XX9F   ;XX = $00 to $DF
;
; Destination: $FE00-$FE9F
hOAMDMA::
    ds DMARoutineEnd - DMARoutine ; Reservamos espacio para copiar la rutina DMA

SECTION "Shadow OAM", WRAM0, ALIGN[8]
; La shadow OAM es una copia de la OAM en memoria RAM normal,
; de tal forma que nosotros podamos escribirla cuando queramos,
; y desde la cual podremos realizar una transferencia DMA.
wShadowOAM:
    ds 4 * 40 ; Sprite data buffer

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
CopyDMARoutineToHRAM::
    ld hl, DMARoutine
    ld b, DMARoutineEnd - DMARoutine ; Número de bytes a copiar
    ld c, LOW(hOAMDMA) ; Low byte de la dirección de destino. en HRAM, etiqueta fija.
.copy
    ld a, [hli]
    inc c
    ldh [c], a  ;; MEM($FF + low byte en c) <- a
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
