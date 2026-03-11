package pixore_internals

import "../traits"
import rl "vendor:raylib"

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
	spritor:        Spritor,
	world:          traits.World,
	root_entity:    traits.Entity,
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


get_real_size :: proc(pixore: Pixore) -> (size: f32, margin: rl.Vector2) {
	win_w := rl.GetScreenWidth()
	win_h := rl.GetScreenHeight()
	if win_w < win_h {
		size = f32(win_w)
		extra_space := f32(win_h - win_w)

		margin = {0, extra_space / 2}
	} else {
		size = f32(win_h)
		extra_space := f32(win_w - win_h)

		margin = {extra_space / 2, 0}
	}

	return size, margin
}
