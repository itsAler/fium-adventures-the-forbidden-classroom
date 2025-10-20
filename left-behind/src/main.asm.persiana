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
velocidad_persiana: DS 2 ; Velocidad de la animación de borrado en persiana.


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
   ; Rellenar en ram las variables
   ld a,  $09
   ld [tile], a
   ld a,  60
   ld [velocidad_persiana], a


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
   
rellenar_persiana: ; for(e=0,e<17,e++) 
   ld a, [velocidad_persiana]
   call waitNvb
   
   ld a,[tile]
   ld b,a   
   push hl  ; Almacenar temporalmente hl
   call fillRow
   pop hl

   ld bc, $20 ; Salto de fila Hcerlo con r16 nos permite evitar overflow con r8
   add hl, bc

   
   ld b,$05 ; Añadir decoración en la fila final
   push hl 
   call fillRow
   pop hl
         
   inc e
   ld a,e
   cp 17 ;; 18 tiles de alto - 1 porque ya escribimos la siguiente fila
   jr nz, rellenar_persiana

   ;; ANIMACIÓN DE APERTURA

   ld e, 0        
   ld hl, $9A20 ; Última fila
abrir_persiana: ; for(e=0,e<17;e++) fila[13-e] = $0
   ld a,[velocidad_persiana]
   call waitNvb

   ld b, $00
   push hl
   call fillRow
   pop hl

   ld a,l            ; hl = Fila anterior
   sub a,$20
   ld l,a
   jr nc, nocarry
   ; resta con underflow
   ld a,h
   sub a,1
   ld h,a
nocarry: ; resta normal

   ld b,$05 ; Añadir decoración en la fila final
   push hl 
   call fillRow
   pop hl
   
   inc e
   ld a,e
   cp 18
   jr nz, abrir_persiana
  
   di     ;; Disable Interrupts
   halt   ;; Halt the CPU (stop procesing here)


         ;;;;;;;;;;;;;;;;;;;
         ;;; SUBRUTINAS ;;;;
         ;;;;;;;;;;;;;;;;;;;

; waitVblank -- Espera hasta VBLANK
waitvb:           
   ld a,[$FF44]
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

; fillRow -- Rellena una fila de la pantalla visible
; 
; Input:
; hl -- Primera posición de la fila.
; b  -- Tile a usar.
;
; Output:
; Nada
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


