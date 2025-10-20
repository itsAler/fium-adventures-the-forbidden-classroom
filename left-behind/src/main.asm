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

   ;; ANIMACIÓN DE CERRADO

   ; Ir rellenando poco a poco las 14 filas
   ; y acto seguido, hacer lo contrario

   ld e,0
   ld hl, $9800 ; primera fila
   ld a,  $09   ; Cargar tile en memoria
   ld [tile], a
rellenar_persiana: ; for(e=0,e<32,e++) 
   call waitvb
   
   ld a,[tile]
   ld b,a   
   ld c, l     ; almacenar temporalmente la direccion de la fila [h|l*]

   call fillRow

   ld l,c ; cargar inicio de la fila en hl 2c 2b
   ld bc, $20 ; Salto de fila
   add hl, bc

   
   ld b,$05 ; Añadir decoración en la fila final
   ld c, l
   call fillRow
         
   inc e
   ld a,e
   cp 18 ;; 18 tiles de alto
   jr nz, rellenar_persiana

   ;; ANIMACIÓN DE APERTURA

   ld hl, $9A20 ; Última fila
vaciar_persiana:
   call waitvb


   ld b, $0    ; Vaciar la fila
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
.ffor:            ;; for(a=0,a<18,a++) *hl=b hl++
   /* IMPLEMENTACIÓN CON HLI, MÁS LENTA
   ld [hl+],a  ; 2c 1b
   inc b       ; 1c 1b
   ld c,a      ; 2c 2b -> 11c 10b
   ld a,b      ; 2c 2b
   cp $14      ; 2c 2b
   ld a,c      ; 2c 2b
   jr nz, .ffor
   */
   ld [hl],b      ;; 2c 1b
   inc l          ;; 1c 1b ->  6c 5b
   inc a          ;; 1c 1b
   cp 20         ;; 2c 2b (20 tiles de largo)
   jr nz, .ffor

   ret


