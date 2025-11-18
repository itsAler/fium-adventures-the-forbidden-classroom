; ANCHOR: entry-point
INCLUDE "src/main/utils/hardware.inc"

SECTION "GameVariables", WRAM0

wLastKeys:: db
wCurKeys:: db
wNewKeys:: db
wGameState::db

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

EntryPoint:

	; Shut down audio circuitry
	xor a
	ld [rNR52], a
	ld a,2
	ld [wGameState], a

	; Wait for the vertical blank phase before initiating the library
    call WaitForOneVBlank

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a


NextGameState::

	call ClearBackground
	call ClearAllSprites

	; Turn the LCD off
	xor a
	ld [rLCDC], a

	ld [rSCX], a
	ld [rSCY], a
	ld [rWY], a
	ld a, 7
	ld [rWX], a
	
	; disable interrupts
	call DisableInterrupts

	; Initiate the next state
	call InitGameplayState

	; Update the next state
	jp UpdateGameplayState


; ANCHOR_END: next-game-state
