INCLUDE "src/main/utils/hardware.inc"

SECTION "GameplayVariables", WRAM0

SECTION "GameplayState", ROM0

; ANCHOR: init-gameplay-state
InitGameplayState::

	call InitializeBackground
	;call InitializePlayer

	; Reseteamos la posición de la ventana.
	xor a
	ld [rWY], a

	ld a, 7
	ld [rWX], a

	; Turn the LCD on
	;ld a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00|LCDCF_BG9800
	ld a, LCDCF_ON | LCDCF_BGON
	ld [rLCDC], a

    ret


UpdateGameplayState::
	jp UpdateGameplayState
