; ANCHOR: gameplay-background-initialize
INCLUDE "src/main/utils/hardware.inc"

SECTION "GameplayBackgroundSection", ROM0

spawnMap: INCBIN "src/generated/background/spawn.tilemap"
spawnEnd:
 
spawnTileData: INCBIN "src/generated/backgrounds/spawn.2bpp"
spawnTileDataEnd:

InitializeBackground::

	; Copy the tile data
	ld de, spawnTileData ; de contains the address where data will be copied from;
	ld hl, _VRAM8000 ; hl contains the address where data will be copied to;
	ld bc, townTileDataEnd - townTileData ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

	; Copy the tilemap
	ld de, townMap
	ld hl, _SCRN0
	ld bc, townMapEnd - townMap

    call CopyDEintoMemoryAtHL

	ret



; This is called during gameplay state on every frame
UpdateBackground::
	ret
