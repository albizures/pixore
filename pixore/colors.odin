package pixore

import "core:fmt"
import rl "vendor:raylib"


// Get the color using its id
get_color :: proc(id: int = -1) -> rl.Color {
	p := (^Pixore)(context.user_ptr)

	id := id if id != -1 else p.color

	color, ok := p.palette[id]

	// NOTE: it might be a good idea to return the zero value here
	assert(ok, fmt.tprint("Color Id, is invalid", id))

	return color
}
