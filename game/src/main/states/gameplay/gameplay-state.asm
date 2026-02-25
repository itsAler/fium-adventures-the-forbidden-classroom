INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

SECTION "GameplayVariables", WRAM0

wBackgroundScroll_X:: dw
wBackgroundScroll_Y:: dw
wBackgroundScroll_X_real:: db
wBackgroundScroll_Y_real:: db

SECTION "Gameplay Tiles", ROM0
gameplayTileset:
	DB $3E,$10,$3E,$00,$60,$00,$78,$00
	DB $3C,$00,$3E,$00,$10,$60,$16,$6E
	DB $07,$3F,$20,$1E,$32,$02,$30,$00
	DB $78,$00,$C8,$00,$8C,$00,$84,$00
	DB $FF,$FF,$BD,$C3,$DB,$A5,$E7,$99
	DB $E7,$99,$DB,$A5,$BD,$C3,$FF,$FF
gameplayTilesetEnd:

SECTION "GameplayState", ROM0
InitGameplayState::
	call InitializeBackground
	call EntityManager_init
	call InitSprObjLib
	call Player_init
	call Box_init

	; Copiar tiles en VRAM
	ld de, gameplayTileset
	ld hl, _VRAM8000
	ld bc, gameplayTilesetEnd - gameplayTileset ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

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
	call Box__update_logic

	call WaitForOneVBlankFunction
	ld a, HIGH(wShadowOAM)
	call hOAMDMA

	jp UpdateGameplayState