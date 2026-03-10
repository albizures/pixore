package traits

import "core:fmt"
import "core:mem"

World :: struct {
	allocator: mem.Allocator,
	entities:  map[Entity_Id]Entity,
}

Entity_Id :: distinct int

Entity :: struct {
	id:     Entity_Id,
	traits: [dynamic]Trait,
}

get_traits :: proc(world: World, id: Entity_Id) -> []Trait {
	return get_entity(world, id).traits[:]
}

get_entity :: proc(world: World, id: Entity_Id) -> ^Entity {
	if id in world.entities {
		return &world.entities[id]
	}

	panic(fmt.tprintln("entity not found:", id))
}

add_child :: proc {
	add_child_by_id,
	add_child_entity,
}

add_child_by_id :: proc(world: World, parent_id: Entity_Id, child_id: Entity_Id) {
	parent := get_entity(world, parent_id)
	child := get_entity(world, child_id)

	append(&parent.traits, Child(child_id))
	append(&child.traits, Parent2(parent_id))
}

make_entity :: proc(world: ^World, traits: ..Trait) -> Entity {
	id := Entity_Id(len(world.entities))

	entity := Entity {
		id     = id,
		traits = make([dynamic]Trait, world.allocator),
	}

	for trait in traits {
		copy := trait
		append(&entity.traits, copy)
	}

	world.entities[id] = entity

	return entity
}

add_child_entity :: proc(world: World, parent: Entity, child: Entity) {
	add_child(world, parent.id, child.id)
}
