package base

import rl "vendor:raylib"

Sprite :: struct {
	size: int,
	// this array should be a square of: <size> x <size>
	data: [dynamic]int,
}

Config :: struct {
	width, height: i32,
	title:         string,
	resolution:    rl.Vector2,
	palette:       []rl.Color,
	sprite:        Sprite,
}


Pixore :: struct {
	width, height:  i32,
	title:          string,
	stop_requested: bool,
	camera:         rl.Camera2D,
	palette:        []rl.Color,
	canvas:         rl.RenderTexture2D,
	resolution:     rl.Vector2,
	color:          int,
	sprite:         Sprite,
}
