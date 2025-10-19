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

;; WAITVBLANK
waitvb: ; VBLANK: 144-153
   ld a,[$FF44]

   cp 144
   jr nz, waitvb ; VBLANK IF >144
;;ENDWAITBLANK  

   ld a, $04
   ld [$9944], a ;; Esto para comprobar que no borra ninguna fila de más :')

   ld hl, $9904      ;; hl = Primera posicion a borrar logo
   ld b, 0           ;; b = tile 0

   ld c, 0
do2row:              ;; borrar dos filas for(c=0,c<1,c++)
   ld a, 0
clearfor:            ;; for(a=0,a<10,a++) *hl=b hl++
   ld [hl],b
   inc hl
   inc a
   cp $10
   jr nz, clearfor

   ld hl, $9924  ; next row 

   inc c
   ld a,c
   cp $2
   jr nz, do2row

   di     ;; Disable Interrupts
   halt   ;; Halt the CPU (stop procesing here)
