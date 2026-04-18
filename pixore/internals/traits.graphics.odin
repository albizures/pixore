package pixore_internals

import "../traits"
import rl "vendor:raylib"

Direction :: enum {
	Full,
	Top,
	Bottom,
	Left,
	Right,
	Vertical,
	Horizontal,
}

Padding :: struct {
	direction: Direction,
	value:     int,
}

Margin :: struct {
	direction: Direction,
	value:     int,
}

Border_Kind :: enum {
	Outside,
	Inside,
}

Border :: struct {
	direction: Direction,
	width:     int,
	color:     rl.Color,
	kind:      Border_Kind,
}

Background :: struct {
	color: rl.Color,
}


Pos :: struct {
	using rect: rl.Rectangle,
}

Position_Type :: enum {
	Relative,
	Absolute,
}

Anchor :: struct {
	using vec: rl.Vector2,
}

// anchor should always be defaulted into {0, 0}
get_anchor :: proc(world: ^traits.World, entity: traits.Entity) -> Anchor {
	anchor, has_anchor := traits.get_trait(world, entity, Anchor)

	if !has_anchor {
		return Anchor{vec = rl.Vector2{}}
	}

	return anchor^
}


// On_Click :: struct {}
