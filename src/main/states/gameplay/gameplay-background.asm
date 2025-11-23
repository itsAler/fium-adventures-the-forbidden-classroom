; ANCHOR: gameplay-background-initialize
INCLUDE "src/main/utils/hardware.inc"

SECTION "GameplayBackgroundSection", ROM0

spawnMap: INCBIN "src/generated/backgrounds/spawn.tilemap"
spawnMapEnd:
 
spawnTileData: INCBIN "src/generated/backgrounds/spawn.2bpp"
spawnTileDataEnd:

InitializeBackground::

	; Copy the tile data
	ld de, spawnTileData 	; de contains the address where data will be copied from;
	ld hl, $9000 			; hl contains the address where data will be copied to;
	ld bc, spawnTileDataEnd - spawnTileData ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

	; Copy the tilemap
	ld de, spawnMap
	ld hl, $9800
	ld bc, spawnMapEnd - spawnMap
    call CopyDEintoMemoryAtHL

	ret

	
; This is called during gameplay state on every frame
UpdateBackground::
	ret
