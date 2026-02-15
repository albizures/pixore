package base

import rl "vendor:raylib"

import se "sprite_editor"

Sprite :: struct {
	size: i32,
	// this array should be a square of: <size> x <size>
	data: [dynamic]uint,
}

Config :: struct #all_or_none {
	width, height: uint,
	title:         string,
	resolution:    rl.Vector2,
	palette:       []rl.Color,
	sprite:        Sprite,
}

Pixore :: struct {
	width, height:  uint,
	title:          string,
	stop_requested: bool,
	camera:         rl.Camera2D,
	palette:        []rl.Color,
	canvas:         rl.RenderTexture2D,
	resolution:     rl.Vector2,
	color:          int,
	sprite:         Sprite,
	sprite_texture: rl.RenderTexture2D,
	sprite_editor:  se.State,
}

PALETTE_CODES := [?]rune {
	'o',
	'1',
	'2',
	'3',
	'4',
	'5',
	'6',
	'7',
	'8',
	'9',
	'0',
	'a',
	'b',
	'c',
	'd',
	'e',
	'f',
	'g',
	'h',
	'i',
	'j',
	'k',
}

palette_codes_to_map :: proc(allocator := context.allocator) -> map[rune]uint {
	codes := make(map[rune]uint)

	for code, index in PALETTE_CODES {
		codes[code] = uint(index)
	}

	return codes
}
