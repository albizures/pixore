package pixore

import rl "vendor:raylib"

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
