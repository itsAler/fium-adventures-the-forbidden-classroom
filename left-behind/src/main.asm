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

;; INCLUDE "hardware.inc"

SECTION "Data", WRAM0[$c000]  
tile: DS 2


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

   ; Espera varias veces a VBLANK

   ; Vamos a esperar 2 segundos. vblank sucede 60 veces por segundo. Esperar 120 veces a vblank equivale a que pasen 2 seg

   ld b,0
wait2sec:
   call waitvb
   inc b
   ld a,b
   cp 120
   jr nz,wait2sec


   ; Haz un borrado en persiana

   ; Ir rellenando poco a poco las 32 filas
   ; y acto seguido, hacer lo contrario

   ld e,0
   ld hl, $9800 ; primera fila
   ld a,  $09   ; Cargar tile en memoria
   ld [tile], a
rellenar_persiana: ; for(e=0,e<32,e++) 
   call waitvb
   
   ld a,[tile]
   ld b,a
   call fillRow

   ld a, $20 ; Salto de fila
   add [hl]

   inc e
   ld a,e
   cp 32
   jr nz, rellenar_persiana

     
   ; Borrar el logo de nintendo, espera a VBLANK

   call waitvb

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

   ; call waitvb

   ld b,  $04
   ld hl, $9A00
   call fillRow



   di     ;; Disable Interrupts
   halt   ;; Halt the CPU (stop procesing here)


; waitVblank -- Espera hasta VBLANK
; Manipula: a
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


