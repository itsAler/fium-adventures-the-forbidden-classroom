
SECTION "MathVariables", WRAM0
randstate:: ds 4
MATH_MULTIPLIER_COUNT:: DB

SECTION "Math", ROM0
;; From: https://github.com/pinobatch/libbet/blob/master/src/rand.z80#L34-L54
; Generates a pseudorandom 16-bit integer in BC
; using the LCG formula from cc65 rand():
; x[i + 1] = x[i] * 0x01010101 + 0xB3B3B3B3
; @return A=B=state bits 31-24 (which have the best entropy),
; C=state bits 23-16, HL trashed
rand::
  ; Add 0xB3 then multiply by 0x01010101
  ld hl, randstate
  ld a, [hl]
  add $B3
  ld [hl+], a
  adc [hl]
  ld [hl+], a
  adc [hl]
  ld [hl+], a
  ld c, a
  adc [hl]
  ld [hl], a
  ld b, a
  ret

; Obtiene el seno de un ángulo
;
; IN:
; A = ángulo
; OUT:
; DE = Q16.0 (En complemento a 2) [-256, 256].
;
; Destruye: hl, de
sinOfAinDE::
    ld l, a
    ld h, 0
    add hl, hl ; como multiplicar x2, ya que trabajmos con 2 Bytes por ángulo
    ld de, sin_lookup_table
    add hl, de ; añadimos offset -> hl con dir a sin(ángulo)
    ld e, [hl] ; Cuidado, están los DW en little endian, cargar primero e
    inc hl
    ld d, [hl]
    ret

; Multiplica HL por A
;
; IN:
; HL = Q16.0 (C2)
; A = Entero sin signo
;
; OUT:
; HL = Q16.0 (C2)
;
; Destruye: HL, A
mulHLbyA::
  cp 0
  jr nz, .mulLoop

  ld h, 0
  ld l, 0
  ret

.mulLoop:
  cp 0
  jr z, .loopEnd

  add hl, hl
  
  dec a
  jr .mulLoop

.loopEnd:
  ret