package pixore_internals

import rl "vendor:raylib"

Entity_Kind :: enum {
	Container,
	Child,
}

Entity :: struct {
	id:       u16,
	kinds:    bit_set[Entity_Kind],
	pos:      rl.Vector2,
	size:     rl.Vector2,
	anchor:   rl.Vector2,
	children: [dynamic]Entity,
}
