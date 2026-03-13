package palette

import "core:mem"
import rl "vendor:raylib"


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

palette_codes_to_map :: proc(allocator := context.allocator) -> map[rune]u8 {
	codes := make(map[rune]u8)

	for code, index in PALETTE_CODES {
		codes[code] = u8(index)
	}

	return codes
}


create_default_palette :: proc(allocator: mem.Allocator) -> [dynamic]rl.Color {
	colors := make([dynamic]rl.Color, allocator)
	append(&colors, rl.Color{0, 0, 0, 0})
	append(&colors, rl.Color{29, 43, 83, 255})
	append(&colors, rl.Color{126, 37, 83, 255})
	append(&colors, rl.Color{0, 135, 81, 255})
	append(&colors, rl.Color{171, 82, 54, 255})
	append(&colors, rl.Color{95, 87, 79, 255})
	append(&colors, rl.Color{194, 195, 199, 255})
	append(&colors, rl.Color{255, 241, 232, 255})
	append(&colors, rl.Color{255, 0, 77, 255})
	append(&colors, rl.Color{255, 163, 0, 255})
	append(&colors, rl.Color{255, 236, 39, 255})
	append(&colors, rl.Color{0, 228, 54, 255})
	append(&colors, rl.Color{41, 173, 255, 255})
	append(&colors, rl.Color{131, 118, 156, 255})
	append(&colors, rl.Color{255, 119, 168, 255})
	append(&colors, rl.Color{255, 204, 170, 255})

	return colors
}
