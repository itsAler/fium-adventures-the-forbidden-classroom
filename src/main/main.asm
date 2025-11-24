; ANCHOR: entry-point
INCLUDE "src/main/utils/hardware.inc"

SECTION "GameVariables", WRAM0

wLastKeys:: db
wCurKeys:: db
wNewKeys:: db

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

EntryPoint:

	; Shut down audio circuitry
	xor a
	ld [rNR52], a

	; Solo se puede apagar la pantalla en VBLANK, o podemos
	; freir el LCD de una gameboy de verdad.
    call WaitForOneVBlank

	; Apagamos LCD, en este punto podemos escribir tiles
	; en la VRAM.
	xor a
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a

	call CopyDMARoutineToHRAM

	call InitGameplayState
	
	jp UpdateGameplayState
