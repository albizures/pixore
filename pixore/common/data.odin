package common

import "../events"
import "../helpers"
import "../traits"
import rl "vendor:raylib"


Pixore :: struct {
	editors:   Editors,
	systems:   Systems,
	resources: Resources,
	config:    Config,
	rendering: Rendering,
	state:     State,
}

Config :: struct {
	using arena: helpers.Arena,
	//
	title:       string,
	window_size: rl.Vector2,
	screen_size: rl.Vector2,
	palette:     [dynamic]rl.Color,
	sprite:      Sprite,
}

Rendering :: struct {
	sprite_texture: rl.RenderTexture2D,
	camera:         rl.Camera2D,
	canvas:         rl.RenderTexture2D,
}

Sprite :: struct {
	size: u16,
	// this array should be a square of: <size> x <size>
	data: [dynamic]u8,
}

Resources :: struct {
	using arena: helpers.Arena,
	// these start out based on the config
	palette:     [dynamic]rl.Color,
	sprite:      Sprite,

	// in the future these should contain: sfx, patterns, etc
}

State :: struct {
	stop_requested: bool,
	selected_color: int,
}

Systems :: struct {
	using arena: helpers.Arena,
	world:       traits.World,
	root_entity: traits.Entity,
	dispatcher:  events.Dispatcher,
}

Editors :: struct {
	spritor: Spritor,
}

// spritor is the union of sprite and editor together 😉
Spritor :: struct {
	using arena:      helpers.Arena,
	status:           Editor_Status,
	last_press_time:  f64,
	// the time between two interactions to be considered a double click
	limit_press_rate: f64,

	// the scale of the sprite
	scale:            int,
	// the offset of the canvas from the top-left corner of the canvas
	offset:           rl.Vector2,


	/// entities
	spritor_id:       traits.Entity,
	canvas_id:        traits.Entity,
	// highlight arround the current color
	current_color_id: traits.Entity,
	color_entities:   [dynamic]traits.Entity,

	// palette columns
	columns:          u8,
}

Editor_Status :: enum {
	Uninitialized,
	Closed,
	Open,
}
