INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

    jp EntryPoint
    ds $150 - @, 0

EntryPoint:

    call waitNvb

    ld a, 0     ; Apagamos la pantalla
    ld [rLCDC], a

    ; Copiar tiles
    ld de, Tiles
    ld hl, $9000
    ld bc, TilesEnd - Tiles
    call Memcopy


    ; Copiar tilemap 
    ld de, Tilemap
    ld hl, $9800
    ld bc, TilemapEnd - Tilemap
    call Memcopy




    ; Limpiamos la zona de memoria ram para objetos OAM
    ; También debe hacerse con la pantalla apagada para acceder
    ; de manera segura a la zona OAM.
    ; Un objeto se almacena en 4 Bytes, que contienen la posY (storedY-16), posX(storedX-8), tileId y atributos.
    ; OAM tiene un tamaño de 160B, por lo que 160/4 = 40 objetos.
    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam


; Encender pantalla, renderizado del background y de objects
    ld a, LCDCF_BGON | LCDCF_ON | LCDCF_OBJON
    ld [rLCDC], a

    ; Modificamos el BackGround Palette: paleta de los 4 colores del bg
    ld a, %11100100
    ld [rBGP], a
    ; Inicializar un Object Palette para los colores de los objetos, OBP0
    ld a, %11100100
    ld [rOBP0], a

Main:

    jp Main

Tiles: INCBIN "bgTiles.2bpp"
TilesEnd:

Tilemap: INCBIN "bg.tilemap"
TilemapEnd:


; waitVblank -- Espera hasta VBLANK
waitvb:           
   ld a,[$FF44] ; rLY
   cp 144
   jr nz, waitvb
   ret 

; waitNtimesVb -- Espera N veces VBLANK
; 
; Input:
; a -- Número de veces a esperar a vblank
;
; Output:
; Nada
;
waitNvb:
.ffor: ;for(a=n,a>0,a--)
   push af
   call waitvb
   pop af

   dec a
   cp 0
   jr nz, .ffor

   ret

Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c 
    jp nz, Memcopy
    ret 