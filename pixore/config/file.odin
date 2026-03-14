package config

import "../common"
import "../helpers"
import "../palette"
import "core:c"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

CONFIG_ARENA_SIZE := 20 * mem.Kilobyte

get_project_config :: proc() -> common.Config {
	bytes, file_error := os.read_entire_file("config.pixore", context.temp_allocator)
	// defer delete(bytes) // this gives 'pointer being freed was not allocated', not sure why
	if file_error != nil {
		log.info("Config not found, creating a new one")
		return create_project_config()
	}
	log.info("Config found, parsing it...")
	content := string(bytes)
	parser := make_parser(content, context.allocator)
	defer destroy_parser(&parser)
	parse(&parser)

	assert(len(parser.errors) == 0, "There are syntax errors in the project file")
	config: common.Config = {
		title = get_string_value(parser.values, "title"),
		window_size = {
			f32(get_uint_value(parser.values, "width")),
			f32(get_uint_value(parser.values, "height")),
		},
		screen_size = {
			f32(get_uint_value(parser.values, "res_x")),
			f32(get_uint_value(parser.values, "res_y")),
		},
		sprite = {size = get_u16_value(parser.values, "sprite_size")},
	}

	helpers.init_arena(&config, CONFIG_ARENA_SIZE)

	config.palette = get_palette(get_array_value(parser.values, "palette"), config.allocator)
	config.sprite.data = get_sprite(get_string_value(parser.values, "sprite"), config.allocator)

	helpers.print_remaining(&config, "config")

	return config
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

get_u16_value :: proc(values: map[string]ConfigValue, name: string) -> u16 {
	value, exists := values[name]
	assert(exists, fmt.tprint("Missing value for:", name))
	real_value, is_valid := value.(uint)
	assert(is_valid, fmt.tprint("Value for \"", name, "\" is not a number"))

	return u16(real_value)
}

get_array_value :: proc(values: map[string]ConfigValue, name: string) -> []Value {
	value, exists := values[name]
	assert(exists, fmt.tprint("Missing value for:", name))

	colors, is_valid := value.([dynamic]Value)
	assert(is_valid, fmt.tprint("Value for \"", name, "\" is not a number"))

	return colors[:]
}

get_palette :: proc(colors: []Value, allocator: mem.Allocator) -> [dynamic]rl.Color {
	palette, allocator_error := make([dynamic]rl.Color, 0, len(colors), allocator)
	assert(allocator_error == .None, "Unable to allocate memory for the palette")

	for maybe_color in colors {
		switch color in maybe_color {
		case string, f32, i64:
		case uint:
			append(&palette, rl.GetColor(c.uint(color)))
		}
	}

	return palette
}

get_sprite :: proc(sprite: string, allocator: mem.Allocator) -> [dynamic]u8 {
	sprite, replaceOk := strings.replace_all(sprite, "\n", "", context.temp_allocator)
	defer delete(sprite)
	assert(replaceOk, "unable to replace enter by spaces")

	values, allocator_error := make([dynamic]u8, 0, len(sprite), allocator)
	assert(allocator_error == .None, "Unable to allocate memory for the sprite")


	codes := palette.palette_codes_to_map()

	for r in sprite {
		value, ok := codes[r]
		assert(ok, "Invalid palette code found")

		append(&values, value)
	}

	return values
}


create_project_config :: proc() -> common.Config {
	sprite_default_size: u16 = 128
	// TODO update this proc to ask for the values instead of using defaults
	config := common.Config {
		title = "My Pixore Game",
		window_size = {800, 500},
		screen_size = {128, 128},
		sprite = {size = sprite_default_size},
	}

	helpers.init_arena(&config, CONFIG_ARENA_SIZE)

	config.palette = palette.create_default_palette(config.allocator)
	config.sprite.data = make(
		[dynamic]u8,
		0,
		sprite_default_size * sprite_default_size,
		config.allocator,
	)

	save_project_config(config)

	return config
}

save_project_config :: proc(config: common.Config) {
	str := serialize(config, context.allocator)
	defer delete(str)

	data_as_bytes := transmute([]byte)(str)

	log.info("Saving file")
	// TODO: handle errors
	error := os.write_entire_file("config.pixore", data_as_bytes)

	if error != nil {
		log.error("Failed to save config: %v", error)
	}
}


save :: proc(p: common.Pixore) {
	log.info("Saving game")


	assert(len(p.resources.palette) == len(p.config.palette), "palette length mismatch")
	copy(p.resources.palette[:], p.config.palette[:])
	copy(p.resources.sprite.data[:], p.config.sprite.data[:])

	// TODO: add other things which can be updated

	save_project_config(p.config)
}

destroy :: proc(config: ^common.Config) {
	mem.arena_free_all(&config.core_arena)
}
