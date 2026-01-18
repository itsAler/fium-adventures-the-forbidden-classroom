INCLUDE "src/main/utils/hardware.inc"

SECTION "GameplayVariables", WRAM0

wBackgroundScroll_X:: dw
wBackgroundScroll_Y:: dw
wBackgroundScroll_X_real:: db
wBackgroundScroll_Y_real:: db

SECTION "GameplayState", ROM0

InitGameplayState::

	call InitializeBackground
	call ClearShadowOAM
	call InitializePlayer
	ld a, HIGH(wShadowOAM)
	call hOAMDMA

	; Reset window and scroll.
	xor a
	ld [rWY], a
	ld [wBackgroundScroll_X], a
	ld [wBackgroundScroll_X+1], a
	ld [wBackgroundScroll_Y], a
	ld [wBackgroundScroll_Y+1], a
	
	ld a, 7
	ld [rWX], a

	; Turn the LCD on
	ld a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG9800
	ld [rLCDC], a

    ret


UpdateGameplayState::
	; Actualizar jugador
	call UpdatePlayer

	call WaitForOneVBlankFunction
	call UpdateBackgroundScroll
	ld a, HIGH(wShadowOAM)
	call hOAMDMA

	jp UpdateGameplayState

; Actualización del BGScroll durante vblank
UpdateBackgroundScroll::
	ld a, [wBackgroundScroll_Y_real]
	ld [rSCY], a
	ld a, [wBackgroundScroll_X_real]
	ld [rSCX], a

	ret
