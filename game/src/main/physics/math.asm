
SECTION "MathVariables", WRAM0
randstate:: ds 4

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

; Almacena en A el entero real de 1 Byte desde un entero escalado de 2 Bytes almacenado en BC.
deEscaleBCtoA::
  ; 5 desplazamientos para un movimiento muy suave.
  srl c
  rr b
  srl c
  rr b
  srl c
  rr b
  srl c
  rr b
  srl c
  rr b

  ld a, b

	ret

; Entrada:
; DE = multiplicando (signed 16)
; A  = multiplicador (8 bit)
; Salida:
; HL = resultado
;
; Destruye: A, HL, DE, B
Mul16x8::
    LD HL, 0
    LD B, 8

.loop:
    SRL A              ; shift right multiplicador
    JR NC, .skip

    ADD HL, DE         ; suma si bit activo

.skip:
    SLA E              ; shift DE << 1
    RL D

    DEC B
    JR NZ, .loop

    RET
