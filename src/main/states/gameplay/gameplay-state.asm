INCLUDE "src/main/utils/hardware.inc"

SECTION "GameplayVariables", WRAM0

bgScroll_X:: db
bgScroll_Y:: db

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
	ld [bgScroll_X], a
	ld [bgScroll_Y], a
	ld a, 7
	ld [rWX], a

	; Turn the LCD on
	ld a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_BG9800
	ld [rLCDC], a

    ret


UpdateGameplayState::

	call WaitForOneVBlankFunction
	; Actualizar jugador
	call UpdatePlayer



	; Actualizar OAM
	ld a, HIGH(wShadowOAM)
	call hOAMDMA

	jp UpdateGameplayState
