; ANCHOR: gameplay-background-initialize
INCLUDE "src/main/utils/hardware.inc"

SECTION "BackgroundVariables", WRAM0


SECTION "GameplayBackgroundSection", ROM0

townMap: INCBIN "src/generated/backgrounds/town.tilemap"
townMapEnd:
 
townTileData: INCBIN "src/generated/backgrounds/town.2bpp"
townTileDataEnd:

InitializeBackground::

	; Copy the tile data
	ld de, townTileData ; de contains the address where data will be copied from;
	ld hl, $9340 ; hl contains the address where data will be copied to;
	ld bc, townTileDataEnd - townTileData ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

	; Copy the tilemap
	ld de, townMap
	ld hl, $9800
	ld bc, townMapEnd - townMap
    call CopyDEintoMemoryAtHL_With52Offset

	ret
; ANCHOR_END: gameplay-background-initialize

; ANCHOR: gameplay-background-update-start
; This is called during gameplay state on every frame
UpdateBackground::
	ret
; ANCHOR_END: gameplay-background-update-end
