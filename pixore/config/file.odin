package config

import "core:c"
import "core:strings"

import "../base"
import "core:fmt"
import "core:log"
import "core:os"
import rl "vendor:raylib"

get_project_config :: proc() -> base.Config {
	bytes, ok := os.read_entire_file("config.pixore", context.temp_allocator)
	// defer delete(bytes) // this gives 'pointer being freed was not allocated', not sure why
	if !ok {
		log.info("Config not found, creating a new one")
		return create_project_config()
	}
	log.info("Config found, parsing it...")
	content := string(bytes)
	parser := make_parser(content, context.allocator)
	defer destroy_parser(&parser)
	parse(&parser)

	assert(len(parser.errors) == 0, "There are syntax errors in the project file")

	title := get_string_value(parser.values, "title")
	width := get_uint_value(parser.values, "width")
	height := get_uint_value(parser.values, "height")
	res_x := get_uint_value(parser.values, "res_x")
	res_y := get_uint_value(parser.values, "res_y")
	palette := get_palette(get_array_value(parser.values, "palette"))
	sprite_size := get_uint_value(parser.values, "sprite_size")
	sprite_data := get_sprite(get_string_value(parser.values, "sprite"))

	return base.Config {
		title = title,
		width = i32(width),
		height = i32(height),
		resolution = {f32(res_x), f32(res_y)},
		palette = palette,
		sprite = {data = sprite_data, size = sprite_size},
	}
}

get_string_value :: proc(values: map[string]ConfigValue, name: string) -> string {
	value, exists := values[name]
	assert(exists, fmt.tprint("Missing value for:", name))
	real_value, is_valid := value.(string)
	assert(is_valid, fmt.tprint("Value for \"", name, "\" is not a string"))

	return strings.clone(real_value)
}

get_uint_value :: proc(values: map[string]ConfigValue, name: string) -> uint {
	value, exists := values[name]
	assert(exists, fmt.tprint("Missing value for:", name))
	real_value, is_valid := value.(uint)
	assert(is_valid, fmt.tprint("Value for \"", name, "\" is not a number"))

	return real_value
}

get_array_value :: proc(values: map[string]ConfigValue, name: string) -> []Value {
	value, exists := values[name]
	assert(exists, fmt.tprint("Missing value for:", name))

	colors, is_valid := value.([dynamic]Value)
	assert(is_valid, fmt.tprint("Value for \"", name, "\" is not a number"))

	return colors[:]
}

get_palette :: proc(colors: []Value) -> []rl.Color {
	palette := make([dynamic]rl.Color)

	for maybe_color in colors {
		switch color in maybe_color {
		case string, f32, i64:
		case uint:
			append(&palette, rl.GetColor(c.uint(color)))
		}
	}

	return palette[:]
}
get_sprite :: proc(sprite: string) -> [dynamic]uint {
	sprite, replaceOk := strings.replace_all(sprite, "\n", "", context.allocator)
	defer delete(sprite)
	assert(replaceOk, "unable to replace enter by spaces")

	values := make([dynamic]uint)

	codes := base.palette_codes_to_map()

	for r in sprite {
		value, ok := codes[r]
		assert(ok, "Invalid palette code found")

		append(&values, value)
	}

	return values
}


create_project_config :: proc() -> base.Config {
	sprite_default_size: uint = 16
	// TODO update this proc to ask for the values instead of using defaults
	config := base.Config {
		width = 800,
		height = 500,
		title = "My Odin Game",
		resolution = {128, 128},
		palette = create_default_palette(),
		sprite = {
			data = make([dynamic]uint, sprite_default_size * sprite_default_size),
			size = sprite_default_size,
		},
	}

	save_project_config(config)

	return config
}

save_project_config :: proc(config: base.Config) {
	str := serialize(config, context.allocator)
	defer delete(str)

	data_as_bytes := transmute([]byte)(str)

	log.info("Saving file")
	// TODO: handle errors
	os.write_entire_file("config.pixore", data_as_bytes)
}


create_default_palette :: proc() -> []rl.Color {
	colors := make([]rl.Color, 16)
	colors[0] = {0, 0, 0, 0}
	colors[1] = {29, 43, 83, 255}
	// colors[2] = rl.BLACK //{126, 37, 83, 255}
	colors[2] = {126, 37, 83, 255}
	colors[3] = {0, 135, 81, 255}
	colors[4] = {171, 82, 54, 255}
	colors[5] = {95, 87, 79, 255}
	colors[6] = {194, 195, 199, 255}
	colors[7] = {255, 241, 232, 255}
	colors[8] = {255, 0, 77, 255}
	colors[9] = {255, 163, 0, 255}
	colors[10] = {255, 236, 39, 255}
	colors[11] = {0, 228, 54, 255}
	colors[12] = {41, 173, 255, 255}
	colors[13] = {131, 118, 156, 255}
	colors[14] = {255, 119, 168, 255}
	colors[15] = {255, 204, 170, 255}

	return colors[:]
}
