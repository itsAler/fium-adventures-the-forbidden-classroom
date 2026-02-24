INCLUDE "src/main/utils/hardware.inc"

SECTION "GameplayVariables", WRAM0

wBackgroundScroll_X:: dw
wBackgroundScroll_Y:: dw
wBackgroundScroll_X_real:: db
wBackgroundScroll_Y_real:: db

SECTION "GameplayState", ROM0
InitGameplayState::
	call InitializeBackground
	call EntityManager_init
	call InitSprObjLib
	call Player_init

	; Reset hardware OAM
	xor a
	ld b, 160
	ld hl, _OAMRAM
	.resetOAM
	ld [hli], a
	dec b
	jr nz, .resetOAM

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
	ld a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ8 | LCDCF_BG9800
	ld [rLCDC], a

    ret



UpdateGameplayState::
	call ResetShadowOAM
    call UpdateInputKeys
	call Player_update_logic

	call WaitForOneVBlankFunction
	ld a, HIGH(wShadowOAM)
	call hOAMDMA

	jp UpdateGameplayState