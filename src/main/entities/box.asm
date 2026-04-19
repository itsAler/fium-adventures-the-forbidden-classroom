INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

SECTION "Box Variables", WRAM0
BOX_VEL::        DB
BOX_ANGLE::      DB
BOX_POS_X::      DW   ;Q12.4 (litte endian)
BOX_POS_Y::      DW   ;Q12.4 (litte endian)

SECTION "Box Graphics", ROM0
boxMetasprite::
  db 16, 8, 2, 0
  db 128 ; Metasprite end

SECTION "Box Entity", rom0
Box_init::

    ; Inicializar atributos
    xor a
    ld [BOX_VEL], a

    ld [BOX_ANGLE], a

    ld [BOX_POS_X], a
    ld [BOX_POS_Y], a

    ld a, 20
    ld [BOX_POS_X + 1], a
    ld [BOX_POS_Y + 1], a

    
   

    ret

Box__update_logic::
    ; Decrementar velocidad hasta quedar en reposo.

    ; Renderizar
    ld a, [BOX_POS_Y + 1]
    ld b, a
    ld a, [BOX_POS_Y]
    ld c, a

    ld a, [BOX_POS_X + 1]
    ld d, a
    ld a, [BOX_POS_X]
    ld e, a
    ld hl, boxMetasprite
    call RenderMetasprite
    ret

