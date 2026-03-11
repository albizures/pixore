package traits

import "core:fmt"
import "core:mem"

Entity :: distinct int

add_trait_2 :: proc(world: ^World, entity_id: Entity, data_1: $T, data_2: $U) {
	add(world, entity_id, data_1)
	add(world, entity_id, data_2)
}
add_trait_3 :: proc(world: ^World, entity_id: Entity, data_1: $T, data_2: $U, data_3: $V) {
	add(world, entity_id, data_1)
	add(world, entity_id, data_2)
	add(world, entity_id, data_3)
}

add_trait_4 :: proc(
	world: ^World,
	entity_id: Entity,
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
	world: ^World,
	entity_id: Entity,
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


expect_trait :: proc(
	world: World,
	entity: Entity,
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
