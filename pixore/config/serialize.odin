package config

import "core:fmt"
import "core:log"
import "core:strings"
import rl "vendor:raylib"

serialize :: proc(config: Config, allocator := context.allocator) -> string {
	log.info("Serializing config")

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	write_string_property(&builder, "title", config.title)
	write_number_property(&builder, "width", f32(config.width))
	write_number_property(&builder, "height", f32(config.height))
	write_number_property(&builder, "res_x", f32(config.resolution.x))
	write_number_property(&builder, "res_y", f32(config.resolution.y))
	write_array_property(&builder, "palette", config.palette)

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


write_array_property :: proc(builder: ^strings.Builder, name: string, palette: []rl.Color) {
	fmt.sbprint(builder, name, "=", "[", sep = "")
	for item, index in palette {
		if (index != 0) {
			fmt.sbprint(builder, ",", sep = "")
		}

		fmt.sbprint(builder, rl.ColorToInt(item), sep = "")
	}

	fmt.sbprintln(builder, "]", sep = "")
}
