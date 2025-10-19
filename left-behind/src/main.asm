;;----------LICENSE NOTICE-------------------------------------------------------------------------------------------------------;;
;;  This file is part of GBTelera: A Gameboy Development Framework                                                               ;;
;;  Copyright (C) 2024 ronaldo / Cheesetea / ByteRealms (@FranGallegoBR)                                                         ;;
;;                                                                                                                               ;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    ;;
;; files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy,    ;;
;; modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the         ;;
;; Softwareis furnished to do so, subject to the following conditions:                                                           ;;
;;                                                                                                                               ;;
;; The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.;;
;;                                                                                                                               ;;
;; THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          ;;
;; WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         ;;
;; COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   ;;
;; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         ;;
;;-------------------------------------------------------------------------------------------------------------------------------;;


SECTION "Entry point", ROM0[$150]

; LVL 1
; Borrar el logo de nintendo, espera a VBLANK
; Rellenar una fila con un tile
; Recuadra el logo de nintendo
; LVL 2
; Espera varias veces a VBLANK
; Haz un borrado en persiana
; LVL 3
; Inventa una animación de borrado

main::


   ; Borrar el logo de nintendo, espera a VBLANK

   call waitvb

   ld a, $04
   ld [$9944], a ;; Esto para comprobar que no borra ninguna fila de más :')

   ld b,  $04
   ld hl, $9800
   call fillRow
   ld hl, $9A00
   call fillRow

   ld hl, $9904      ;; hl = Primera posicion a borrar logo
   ld b, 0           ;; b = tile 0

   ld c, 0
do2row:              ;; borrar dos filas for(c=0,c<1,c++)
   ld a, 0
clearfor:            ;; for(a=0,a<10,a++) *hl=b hl++
   ld [hl],b      ;; 2c 1b
   inc l          ;; 1c 1b ->  6c 5b
   inc a          ;; 1c 1b
   cp $10         ;; 2c 2b
   jr nz, clearfor

   ld hl, $9924  ; next row 

   inc c
   ld a,c
   cp $2
   jr nz, do2row


   ; Rellenar una fila con un tile

   call waitvb



   di     ;; Disable Interrupts
   halt   ;; Halt the CPU (stop procesing here)


; waitVblank -- Espera hasta VBLANK
waitvb:           
   ld a,[$FF44]
   cp 144
   jr nz, waitvb
   ret 

; fillRow -- Rellena una fila de la pantalla visible
; 
; Input:
; hl -- Primera posición de la fila.
; b  -- Tile a usar.
;
; Output:
; Nada
;
; Manipula: hl,b,a
fillRow:

   ld a,0
.ffor:            ;; for(a=0,a<10,a++) *hl=b hl++
   /* IMPLEMENTACIÓN CON HLI, MÁS LENTA
   ld [hl+],a  ; 2c 1b
   inc b       ; 1c 1b
   ld c,a      ; 2c 2b -> 11c 10b
   ld a,b      ; 2c 2b
   cp $20      ; 2c 2b
   ld a,c      ; 2c 2b
   jr nz, .ffor
   */
   ld [hl],b      ;; 2c 1b
   inc l          ;; 1c 1b ->  6c 5b
   inc a          ;; 1c 1b
   cp $20         ;; 2c 2b
   jr nz, .ffor

   ret


