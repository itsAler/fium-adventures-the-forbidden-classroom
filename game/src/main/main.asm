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
; ANCHOR_END: entry-point
	
; ANCHOR: entry-point-end
	; Shut down audio circuitry
	xor a
	ld [rNR52], a
	ld a,2
	ld [wGameState], a

	; Wait for the vertical blank phase before initiating the library
    call WaitForOneVBlank

	; from: https://github.com/eievui5/gb-sprobj-lib
	; The library is relatively simple to get set up. First, put the following in your initialization code:
	; Initilize Sprite Object Library.
	call InitSprObjLibWrapper

	; Turn the LCD off
	xor a
	ld [rLCDC], a

	; Turn the LCD on
	ld a, LCDCF_ON  | LCDCF_BGON|LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a

; ANCHOR_END: entry-point-end
; ANCHOR: next-game-state

NextGameState::

	; Do not turn the LCD off outside of VBlank
    call WaitForOneVBlank

	call ClearBackground


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
	
	; Clear all sprites
	call ClearAllSprites

	; Initiate the next state
	call z, InitGameplayState

	; Update the next state
	jp z, UpdateGameplayState


; ANCHOR_END: next-game-state
