package pixore_internals

import "core:c"
import rl "vendor:raylib"
import gl "vendor:raylib/rlgl"

// Get the color using its id
get_color :: proc(id: int = -1) -> rl.Color {
	p := (^Pixore)(context.user_ptr)

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
	p := (^Pixore)(context.user_ptr)
	image := rl.LoadImageFromTexture(p.canvas.texture)
	defer rl.UnloadImage(image)
	color := rl.GetImageColor(image, c.int(x), c.int(y))

	return color
}


circle :: proc(x, y, radius: int, id: int = -1) {
	rl.DrawCircleLines(c.int(x), c.int(y), f32(radius), get_color(id))
}
circle_fill :: proc(x, y, radius: int, id: int = -1) {
	rl.DrawCircle(c.int(x), c.int(y), f32(radius), get_color(id))
}

rect :: proc(x, y, w, h: int, id: int = -1) {
	x := c.int(x)
	y := c.int(y)
	h := c.int(h)
	w := c.int(w)
	// manually drawing the rectangle because using raylib DrawRectangleLines
	// get some pixel off
	// rl.DrawRectangleLines(x, y, c.int(w), c.int(h), get_color(id))
	color := get_color(id)
	// similar to DrawRectangleLines we need to adjust some pixels
	// TODO: use DrawRectanglePro with the same values bellow
	rl.DrawLine(x + 0, y + 1, x + w, y + 1, color)
	rl.DrawLine(x + 0, y + 0, x + 0, y + h, color)
	rl.DrawLine(x + w - 1, y + 0, x + w - 1, y + h, color)
	rl.DrawLine(x + 0, y + h, x + w, y + h, color)
}

rect_fill :: proc(x, y, w, h: int, id: int = -1) {
	rl.DrawRectangle(c.int(x), c.int(y), c.int(w), c.int(h), get_color(id))
}

ellipse :: proc(x, y, rx, ry: int, color: int = -1) {
	rl.DrawEllipseLines(c.int(x), c.int(y), f32(rx), f32(ry), get_color())
}
ellipse_fill :: proc(x, y, rx, ry: int, color: int = -1) {
	rl.DrawEllipse(c.int(x), c.int(y), f32(rx), f32(ry), get_color())
}

cls :: proc(id: int = -1) {
	rl.ClearBackground(get_color(id))
}


push :: proc() {
	gl.PushMatrix()
}

pop :: proc() {
	gl.PopMatrix()
}

translate :: proc(x: f32 = 0, y: f32 = 0) {
	gl.Translatef(x, y, 0)
}

set_offset :: proc(x, y: f32) {
	p := (^Pixore)(context.user_ptr)
	p.camera.offset = rl.Vector2{x, y}
}

delta_time :: proc() -> f32 {
	return rl.GetFrameTime()
}

win_size :: proc() -> (x: int, y: int) {
	p := (^Pixore)(context.user_ptr)
	return int(p.resolution.x), int(p.resolution.y)
}


is_key_pressed :: proc(key: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressed(key)
}

is_key_pressed_again :: proc(key: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressedRepeat(key)
}

spr :: proc(x, y, width, height, dest_x, dest_y: int) {
	p := (^Pixore)(context.user_ptr)

	width := f32(width)
	height := f32(height)
	x := f32(x)
	y := -height - f32(y) // flipping because of OpenGL
	dest_x := f32(dest_x)
	dest_y := f32(dest_y)

	rl.DrawTexturePro(
		p.sprite_texture.texture,
		{x, y, width, -height},
		{dest_x, dest_y, width, height},
		{0, 0},
		0,
		rl.WHITE,
	)
}
