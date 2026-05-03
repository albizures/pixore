package pixore_memory

import rl "vendor:raylib"

import "../traits"


SPRITE_SIZE :: 128
SPRITE_PIXELS :: SPRITE_SIZE * SPRITE_SIZE
PALETTE_SIZE :: 16

Sprite_Data :: distinct [SPRITE_PIXELS]u8
Palette :: distinct [PALETTE_SIZE]rl.Color
Color_Entities :: distinct [PALETTE_SIZE]traits.Entity
