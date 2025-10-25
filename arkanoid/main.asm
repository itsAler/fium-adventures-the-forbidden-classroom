INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

    jp EntryPoint

    ds $150 - @, 0

EntryPoint:
    /*
        Apagar el LCD puede surtir el curioso 
        efecto de cargarse la pantalla.
        Con el fin de evitar este suceso, solo 
        apagaremos la pantalla (necesario para 
        cargar los tiles) cuando estemos en VBLANK.

        Tan grave puede llegar a ser este asunto, 
        que la propia nintendo pasaba un control
        de calidad a los videojuegos a publicar
        y no lo hacían si esto no se cumplía.
    */

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


    ; Copiar tile del paddle
    ld de, Paddle
    ld hl, $8000
    ld bc, PaddleEnd - Paddle
    call Memcopy

	; Copiar tile de la pelota
    ld de, Ball
    ld hl, $8010
    ld bc, BallEnd - Ball
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

	; Inicializar OAM para el paddle
	; ESTRUCTURA OAM -> [Y][X][TileIdx][Attributes: (b7:Priority)(b6:yFlip)(b5:xFlip)(b4:DMGPallete)(b3:Bank)(b2-0:CGBPallete)]

    ld hl, _OAMRAM
    ld a, 128 + 16  ; Y 
    ld [hli], a
    ld a, 16 + 8    ; X
    ld [hli], a
    ld a, 0
    ld [hli], a     ; TileID 0
    ld [hli], a     ; Attributes 0

	; Inicializar OAM para la pelota
    ld a, 100 + 16 
    ld [hli], a
    ld a, 32 + 8
    ld [hli], a
    ld a, 1 
    ld [hli], a
    ld a, 0
    ld [hli], a

	 ; La pelota se inicializa moviéndose hacia arriba y hacia la derecha
	 ; (posiciones de memoria decrecientes para Y+ y crecientes para X+)
    ld a, 1
    ld [wBallMomentumX], a
    ld a, -1
    ld [wBallMomentumY], a



    ; Encender pantalla, renderizado del background y de objects
    ld a, LCDCF_BGON | LCDCF_ON | LCDCF_OBJON
    ld [rLCDC], a

    ; Modificamos el BackGround Palette: paleta de los 4 colores del bg
    ld a, %11100100
    ld [rBGP], a
    ; Inicializar un Object Palette para los colores de los objetos, OBP0
    ld a, %11100100
    ld [rOBP0], a
    
    ; Inicializar las variables
    ld a, 0
    ld [wFrameCounter], a
    ld [wCurKeys], a
    ld [wNewKeys], a

Main:
    ; Esperar a vBlank
    call waitvb
    call waitvb

	; Mover la pelota, para lo cual añadir el momento guardado en OAM
	; ball.OAM.X += wBallMomentumX
    ld a, [wBallMomentumX] 		
    ld b, a
    ld a, [_OAMRAM + 5]			
    add a, b
    ld [_OAMRAM + 5], a			
	; ball.OAM.y += wBallMomentumY
    ld a, [wBallMomentumY]
    ld b, a
    ld a, [_OAMRAM + 4]
    add a, b
    ld [_OAMRAM + 4], a

	; Comprobar colisiones de la pelota

BounceOnTop:
    ; Remember to offset the OAM position!
    ; (8, 16) in OAM coordinates is (0, 0) on the screen.
	; if isWallTile(getTileByPixel(ball.OAM.y - 1, ball.OAM.x)) then wBallMomentumY++
    ld a, [_OAMRAM + 4] 
	sub a, 16 + 1				
    ld c, a						
    ld a, [_OAMRAM + 5]         
    sub a, 8
    ld b, a						
    call GetTileByPixel 		
    ld a, [hl]					
    call IsWallTile				
    jp nz, BounceOnRight
    ld a, 1
    ld [wBallMomentumY], a
	
BounceOnRight:
	; if isWallTile(getTileByPixel(ball.OAM.y, ball.OAM.x + 1)) then wBallMomentumX--
    ld a, [_OAMRAM + 4]
    sub a, 16
    ld c, a
    ld a, [_OAMRAM + 5]
    sub a, 8 - 1
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnLeft
    ld a, -1
    ld [wBallMomentumX], a

BounceOnLeft:
	; if isWallTile(getTileByPixel(ball.OAM.y, ball.OAM.x - 1)) then wBallMomentumX++
    ld a, [_OAMRAM + 4]
    sub a, 16
    ld c, a
    ld a, [_OAMRAM + 5]
    sub a, 8 + 1
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceOnBottom
    ld a, 1
    ld [wBallMomentumX], a

BounceOnBottom:
	; if isWallTile(getTileByPixel(ball.OAM.y + 1, ball.OAM.x)) then wBallMomentumY--
    ld a, [_OAMRAM + 4]
    sub a, 16 - 1
    ld c, a
    ld a, [_OAMRAM + 5]
    sub a, 8
    ld b, a
    call GetTileByPixel
    ld a, [hl]
    call IsWallTile
    jp nz, BounceDone
    ld a, -1
    ld [wBallMomentumY], a
BounceDone:

	; Comprobar colisión con el paddle
	; First, check if the ball is low enough to bounce off the paddle.
	; if paddle.OAM.y == ball.OAM.y then comprobarColisionEjeX()
    ld a, [_OAMRAM]
    ld b, a
    ld a, [_OAMRAM + 4]
    cp a, b
    jp nz, PaddleBounceDone ; If the ball isn't at the same Y position as the paddle, it can't bounce.

    ; comprobarColisionEjeX()
	;
    ld a, [_OAMRAM + 5] ; Ball's X position.
    ld b, a
    ld a, [_OAMRAM + 1] ; Paddle's X position.
    sub a, 8			; Esto se explica guay con el dibujo de la web: 
    cp a, b
    jp nc, PaddleBounceDone
    add a, 8 + 16 ; 8 to undo, 16 as the width.
    cp a, b
    jp c, PaddleBounceDone

    ld a, -1
    ld [wBallMomentumY], a

PaddleBounceDone:

    ; Comprobar el input por cada frame
    call UpdateKeys

    ; Comprobar dpad izq.
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT ; etq que nos da directamente los bits de la máscara de inputs de la izq.
    jp z, CheckRight
Left:
    ; Move the paddle one pixel to the left.
    ld a, [_OAMRAM + 1]
    dec a
    ; If we've already hit the edge of the playfield, don't move.
    cp a, 15
    jp z, Main
    ld [_OAMRAM + 1], a
    jp Main

; Then check the right button.
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, Main
Right:
    ; Move the paddle one pixel to the right.
    ld a, [_OAMRAM + 1]
    inc a
    ; If we've already hit the edge of the playfield, don't move.
    cp a, 105
    jp z, Main
    ld [_OAMRAM + 1], a



    jp Main

Tiles:
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33322222
	dw `33322222
	dw `33322222
	dw `33322211
	dw `33322211

	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111

	dw `33333333
	dw `33333333
	dw `33333333
	dw `22222333
	dw `22222333
	dw `22222333
	dw `11222333
	dw `11222333

	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333
	dw `33333333

	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211
	dw `33322211

	dw `22222222
	dw `20000000
	dw `20111111
	dw `20111111
	dw `20111111
	dw `20111111
	dw `22222222
	dw `33333333

	dw `22222223
	dw `00000023
	dw `11111123
	dw `11111123
	dw `11111123
	dw `11111123
	dw `22222223
	dw `33333333

	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333
	dw `11222333

	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `11001100
	dw `11111111
	dw `11111111
	dw `21212121
	dw `22222222
	dw `22322232
	dw `23232323
	dw `33333333

    dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222211
	dw `22222211
	dw `22222211

	dw `22222222
	dw `22222222
	dw `22222222
	dw `11111111
	dw `11111111
	dw `11221111
	dw `11221111
	dw `11000011

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11222222
	dw `11222222
	dw `11222222

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222

	dw `22222211
	dw `22222200
	dw `22222200
	dw `22000000
	dw `22000000
	dw `22222222
	dw `22222222
	dw `22222222

	dw `11000011
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11000022

	dw `11222222
	dw `11222222
	dw `11222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222

	dw `22222222
	dw `22222200
	dw `22222200
	dw `22222211
	dw `22222211
	dw `22221111
	dw `22221111
	dw `22221111

	dw `11000022
	dw `00112222
	dw `00112222
	dw `11112200
	dw `11112200
	dw `11220000
	dw `11220000
	dw `11220000

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22000000
	dw `22000000
	dw `00000000
	dw `00000000
	dw `00000000

	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `22222222
	dw `11110022
	dw `11110022
	dw `11110022

	dw `22221111
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22221111
	dw `22222211
	dw `22222211
	dw `22222222

	dw `11220000
	dw `11110000
	dw `11110000
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `22222222

	dw `00000000
	dw `00111111
	dw `00111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `11111111
	dw `22222222

	dw `11110022
	dw `11000022
	dw `11000022
	dw `00002222
	dw `00002222
	dw `00222222
	dw `00222222
	dw `22222222


TilesEnd:

Tilemap:
	db $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $05, $06, $05, $06, $05, $06, $05, $06, $05, $06, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0A, $0B, $0C, $0D, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $0E, $0F, $10, $11, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $12, $13, $14, $15, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $07, $03, $16, $17, $18, $19, $03, 0,0,0,0,0,0,0,0,0,0,0,0
	db $04, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $07, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
TilemapEnd:

Paddle:
    dw `13333331
    dw `30000003
    dw `13333331
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
PaddleEnd:

Ball:
    dw `00033000
    dw `00322300
    dw `03222230
    dw `03222230
    dw `00322300
    dw `00033000
    dw `00000000
    dw `00000000
BallEnd:



    

         ;;;;;;;;;;;;;;;;;;;
         ;;; SUBRUTINAS ;;;;
         ;;;;;;;;;;;;;;;;;;;

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
    
   ; Copia bytes de un área a otra
   ; @param de: Origen
   ; @param hl: Destino
   ; @param bc: Longitud de los datos
Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b ; Forma entelegente de comparar si un r16 es 0.
    or a, c ; Comparar con or sus r8 y el resultado indica si hay algún 1 (número!=0 -> z=0 -> nz)
    jp nz, Memcopy
    ret 

    ; Lee los inputs de los controles de la GameBoy
UpdateKeys:
    ; Poll half the controller 
    ld a, P1F_GET_BTN
    call .onenibble
    ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

    ; Leer el pad
    ld a, P1F_GET_DPAD
    call .onenibble
    swap a ; A7-4 = unpressed directions; A3-0 = 1
    xor a, b ; A = pressed buttons + directions
    ld b, a ; B = pressed buttons + dirs

    ; Release the controller
    ld a, P1F_GET_NONE
    ldh [rP1], a

    ; Combine with previous wCurKeys to make wNewKeys
    ld a, [wCurKeys]
    xor a, b ; A = keys that changed state
    and a, b ; A = keys that changed to pressed
    ld [wNewKeys], a
    ld a, b
    ld [wCurKeys], a
    ret

.onenibble
    ldh [rP1], a ; switch the key matrix
    call .knownret ; burn 10 cycles calling a known ret
    ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
    ldh a, [rP1]
    ldh a, [rP1] ; this read counts
    or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
    ret


; Convert a pixel position to a tilemap address
; hl = $9800 + X + Y * 32
; @param b: X
; @param c: Y
; @return hl: tile address
GetTileByPixel:
    ; First, we need to divide by 8 to convert a pixel position to a tile position.
    ; After this we want to multiply the Y position by 32.
    ; These operations effectively cancel out so we only need to mask the Y value.
    ld a, c
    and a, %11111000
    ld l, a
    ld h, 0
    ; Now we have the position * 8 in hl
    add hl, hl ; position * 16
    add hl, hl ; position * 32
    ; Convert the X position to an offset.
    ld a, b
    srl a ; a / 2
    srl a ; a / 4
    srl a ; a / 8
    ; Add the two offsets together.
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; Add the offset to the tilemap's base address, and we are done!
    ld bc, $9800
    add hl, bc
    ret

; @param a: tile ID
; @return z: set if a is a wall.
IsWallTile:
    cp a, $00 		; if a == 0; flag.z = 1 
    ret z			; ret solo si está activo el flag, si no, prosigue con la lista de tiles a comprobar.
    cp a, $01
    ret z
    cp a, $02
    ret z
    cp a, $04
    ret z
    cp a, $05
    ret z
    cp a, $06
    ret z
    cp a, $07
    ret



SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Ball Data", WRAM0
wBallMomentumX: db
wBallMomentumY: db


