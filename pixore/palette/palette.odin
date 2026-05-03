package palette

import "core:mem"
import rl "vendor:raylib"

import "../memory"

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


create_default_palette :: proc() -> (palette: memory.Palette) {
	palette[0] = rl.Color{0, 0, 0, 0}
	palette[1] = rl.Color{29, 43, 83, 255}
	palette[2] = rl.Color{126, 37, 83, 255}
	palette[3] = rl.Color{0, 135, 81, 255}
	palette[4] = rl.Color{171, 82, 54, 255}
	palette[5] = rl.Color{95, 87, 79, 255}
	palette[6] = rl.Color{194, 195, 199, 255}
	palette[7] = rl.Color{255, 241, 232, 255}
	palette[8] = rl.Color{255, 0, 77, 255}
	palette[9] = rl.Color{255, 163, 0, 255}
	palette[10] = rl.Color{255, 236, 39, 255}
	palette[11] = rl.Color{0, 228, 54, 255}
	palette[12] = rl.Color{41, 173, 255, 255}
	palette[13] = rl.Color{131, 118, 156, 255}
	palette[14] = rl.Color{255, 119, 168, 255}
	palette[15] = rl.Color{255, 204, 170, 255}

	return palette
}
