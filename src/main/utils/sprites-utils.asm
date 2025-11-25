
include "src/main/utils/hardware.inc"

SECTION "SpriteVariables", WRAM0

wPlayerSprites: ds 4 * 1 ; 4 bytes/sprite * 1 sprite (doble, LCDCF_OBJ16=1)


SECTION "Shadow OAM", WRAM0, ALIGN[8]
; La shadow OAM es una copia de la OAM en memoria RAM normal,
; de tal forma que nosotros podamos escribirla cuando queramos,
; y desde la cual podremos realizar una transferencia DMA.
wShadowOAM::
    ds 4 * 40 ; Sprite data buffer 40 sprites * 4 bytes


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
    ldh [c], a  ;; MEM($FF + low byte en c) <- a
    inc c
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

; Rutina de limpieza de la shadowOAM
ClearShadowOAM::
    xor a
    ld b, 160
    ld hl, wShadowOAM
ClearShadowoam:
    ld [hli], a
    dec b
    jp nz, ClearShadowoam
    ret 


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