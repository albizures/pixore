package traits

import "core:fmt"
import "core:mem"

Entity_Id :: distinct int

add_child :: proc(
	world: ^World2,
	parent_id: Entity_Id,
	child_id: Entity_Id,
	allocator := context.allocator,
) {
	if children, has_children := get_trait(world^, parent_id, Children); has_children {
		append(&children.entities, child_id)
		add(world, child_id, Parent2(parent_id))

		return
	}

	add(
		world,
		parent_id,
		Children{allocator = allocator, entities = make([dynamic]Entity_Id, allocator)},
	)

	// and we do it again but now with the parent having an initialized Children trait
	add_child(world, parent_id, child_id)
}


add_trait_2 :: proc(world: ^World2, entity_id: Entity_Id, data_1: $T, data_2: $U) {
	add(world, entity_id, data_1)
	add(world, entity_id, data_2)
}
add_trait_3 :: proc(world: ^World2, entity_id: Entity_Id, data_1: $T, data_2: $U, data_3: $V) {
	add(world, entity_id, data_1)
	add(world, entity_id, data_2)
	add(world, entity_id, data_3)
}

add_trait_4 :: proc(
	world: ^World2,
	entity_id: Entity_Id,
	data_1: $T,
	data_2: $U,
	data_3: $V,
	data_4: $W,
) {
	add(world, entity_id, data_1)
	add(world, entity_id, data_2)
	add(world, entity_id, data_3)
	add(world, entity_id, data_4)
}

add_trait_5 :: proc(
	world: ^World2,
	entity_id: Entity_Id,
	data_1: $T,
	data_2: $U,
	data_3: $V,
	data_4: $W,
	data_5: $X,
) {
	add(world, entity_id, data_1)
	add(world, entity_id, data_2)
	add(world, entity_id, data_3)
	add(world, entity_id, data_4)
	add(world, entity_id, data_5)
}
