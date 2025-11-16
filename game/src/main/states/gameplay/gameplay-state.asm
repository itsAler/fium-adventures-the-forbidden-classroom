; ANCHOR: gameplay-data-variables
INCLUDE "src/main/utils/hardware.inc"

SECTION "GameplayVariables", WRAM0

SECTION "GameplayState", ROM0

; ANCHOR_END: gameplay-data-variables

; ANCHOR: init-gameplay-state
InitGameplayState::

	call InitializeBackground
	;call InitializePlayer

	; Initiate STAT interrupts
	call InitStatInterrupts

	xor a
	ld [rWY], a

	ld a, 7
	ld [rWX], a

	; Turn the LCD on
	ld a, LCDCF_ON  | LCDCF_BGON|LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00|LCDCF_BG9800
	ld [rLCDC], a

    ret
; ANCHOR_END: init-gameplay-state
	
; ANCHOR: update-gameplay-state-start
UpdateGameplayState::

	; save the keys last frame
	ld a, [wCurKeys]
	ld [wLastKeys], a

	; This is in input.asm
	; It's straight from: https://gbdev.io/gb-asm-tutorial/part2/input.html
	; In their words (paraphrased): reading player input for gameboy is NOT a trivial task
	; So it's best to use some tested code
    call Input
; ANCHOR_END: update-gameplay-state-start

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Call our function that performs the code
    call WaitForOneVBlank
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	jp UpdateGameplayState

EndGameplay:
	
    ld a, 0
    ld [wGameState],a
    jp NextGameState
; ANCHOR_END: update-gameplay-end-update
