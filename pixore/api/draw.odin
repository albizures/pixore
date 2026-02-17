package api

import "core:c"
import rl "vendor:raylib"

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
