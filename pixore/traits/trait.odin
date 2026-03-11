package traits

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

// Basically a component but with a short name
Trait :: union #no_nil {
	Rect,
	Pos,
	Size,
	Anchor,
	Border,
	Background,
	Margin,
	Padding,
	Position,

	// connections
	Parent2,
	Child,

	// flags
	Is_Mouse_Interactive,


	// events
	On_Click,
}

Rect :: struct {
	using rect: rl.Rectangle,
}

Parent2 :: distinct Entity_Id

Child :: distinct Entity_Id

Children :: struct {
	allocator: mem.Allocator,
	entities:  [dynamic]Entity_Id,
}

Position :: enum {
	Relative,
	Absolute,
}

On_Click :: struct {
	callback: proc(data: rawptr),
}

Pos :: distinct rl.Vector2

Size :: distinct rl.Vector2

Anchor :: struct {
	using vec: rl.Vector2,
}

expect_trait :: proc(
	world: World2,
	entity: Entity_Id,
	$Type: typeid,
	message: string,
	loc := #caller_location,
) -> ^Type {
	trait :=
		get_trait(world, entity, Type) or_else panic(
			fmt.tprintln(message, ": name =", type_info_of(Type).id, ", entity =", entity),
			loc,
		)

	return trait
}

// anchor should always be defaulted into {0, 0}
get_anchor :: proc(world: World2, entity: Entity_Id) -> Anchor {
	anchor, has_anchor := get_trait(world, entity, Anchor)

	if !has_anchor {
		return Anchor{vec = rl.Vector2{}}
	}

	return anchor^
}
