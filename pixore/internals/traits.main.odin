package pixore_internals

import "../traits"
import "core:mem"

Parent :: struct {
	entity: traits.Entity_Id,
}
Children :: struct {
	allocator: mem.Allocator,
	entities:  [dynamic]traits.Entity_Id,
}

add_child :: proc(
	world: ^traits.World,
	parent_id: traits.Entity_Id,
	child_id: traits.Entity_Id,
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
		Children{allocator = allocator, entities = make([dynamic]traits.Entity_Id, allocator)},
	)

	// and we do it again but now with the parent having an initialized Children trait
	add_child(world, parent_id, child_id)
}

On_Click :: struct {
	callback: proc(data: rawptr),
}
