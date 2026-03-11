package pixore_internals

import "../traits"
import "core:mem"

Parent :: struct {
	entity: traits.Entity,
}
Children :: struct {
	allocator: mem.Allocator,
	entities:  [dynamic]traits.Entity,
}

add_child :: proc {
	add_one_child,
	add_children,
}

add_one_child :: proc(
	world: ^traits.World,
	parent_id: traits.Entity,
	child_id: traits.Entity,
	allocator := context.allocator,
) {
	if children, has_children := traits.get_trait(world^, parent_id, Children); has_children {
		append(&children.entities, child_id)
		traits.add(world, child_id, Parent{entity = parent_id})

		return
	}

	traits.add(
		world,
		parent_id,
		Children{allocator = allocator, entities = make([dynamic]traits.Entity, allocator)},
	)

	// and we do it again but now with the parent having an initialized Children trait
	add_child(world, parent_id, child_id)
}

add_children :: proc(
	world: ^traits.World,
	parent_id: traits.Entity,
	child_ids: ..traits.Entity,
	allocator := context.allocator,
) {
	for child_id in child_ids {
		add_child(world, parent_id, child_id, allocator)
	}
}
