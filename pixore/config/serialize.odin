package config

import "../base"
import "core:fmt"
import "core:log"
import "core:strings"
import rl "vendor:raylib"

serialize :: proc(config: base.Config, allocator := context.allocator) -> string {
	log.info("Serializing config")

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	write_string_property(&builder, "title", config.title)
	write_number_property(&builder, "width", f32(config.width))
	write_number_property(&builder, "height", f32(config.height))
	write_number_property(&builder, "res_x", f32(config.resolution.x))
	write_number_property(&builder, "res_y", f32(config.resolution.y))
	write_palette(&builder, config.palette)
	write_number_property(&builder, "sprite_size", f32(config.sprite.size))
	write_sprite(&builder, config.sprite)

	return strings.clone(strings.to_string(builder))
}

write_string_property :: proc(
	builder: ^strings.Builder,
	name: string,
	value: any,
	is_multiline := false,
) {
	if is_multiline {
		fmt.sbprintln(builder, name, "=", MULTILINE, "\n", value, "\n", MULTILINE, sep = "")
	} else {
		fmt.sbprintln(builder, name, "=\"", value, "\"", sep = "")
	}
}

write_number_property :: proc(builder: ^strings.Builder, name: string, value: f32) {
	fmt.sbprintln(builder, name, "=", value, sep = "")
}


write_palette :: proc(builder: ^strings.Builder, palette: []rl.Color) {
	fmt.sbprint(builder, "palette=[", sep = "")
	for item, index in palette {
		if (index != 0) {
			fmt.sbprint(builder, ",", sep = "")
		}

		fmt.sbprint(builder, rl.ColorToInt(item), sep = "")
	}

	fmt.sbprintln(builder, "]", sep = "")
}

write_sprite :: proc(builder: ^strings.Builder, sprite: base.Sprite) {
	fmt.sbprint(builder, `sprite="""`, sep = "")
	for item, index in sprite.data {
		if i32(index) % sprite.size == 0 {
			fmt.sbprint(builder, "\n", sep = "")
		}

		assert(
			item < len(base.PALETTE_CODES),
			"It seems the palette is too long, increase palette code",
		)

		fmt.sbprint(builder, base.PALETTE_CODES[item], sep = "")
	}

	fmt.sbprintln(builder, `"""`, sep = "")
}
