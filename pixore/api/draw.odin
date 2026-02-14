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
	rl.DrawRectangleLines(c.int(x), c.int(y), c.int(w), c.int(h), get_color(id))
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
