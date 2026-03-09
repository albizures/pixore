package helpers

import "vendor:raylib"

add_rect_to_vec :: proc(rect: raylib.Rectangle, vec: ^raylib.Vector2) {
	vec.x += rect.x
	vec.y += rect.y
}


add_vec_to_rect :: proc(vec: raylib.Vector2, rect: ^raylib.Rectangle) {
	rect.x += vec.x
	rect.y += vec.y
}
