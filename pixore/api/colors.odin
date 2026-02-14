package api

import "../base"
import "core:c"
import rl "vendor:raylib"

// Get the color using its id
get_color :: proc(id: int = -1) -> rl.Color {
	p := (^base.Pixore)(context.user_ptr)

	id := id

	if id >= len(p.palette) {
		id = -1
	}

	id = id if id != -1 else p.color

	color := p.palette[id]

	return color
}

// Set a single pixel to a color
set_pixel :: proc(x, y: int, color: int = -1) {
	rl.DrawPixel(c.int(x), c.int(y), get_color(color))
}

// Get the color of a specific pixel
get_pixel :: proc(x, y: int) -> rl.Color {
	p := (^base.Pixore)(context.user_ptr)
	image := rl.LoadImageFromTexture(p.canvas.texture)
	defer rl.UnloadImage(image)
	color := rl.GetImageColor(image, c.int(x), c.int(y))

	return color
}
