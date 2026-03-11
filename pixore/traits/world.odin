package traits

import "core:fmt"
import "core:log"
import "core:mem"

World :: struct {
	allocator: mem.Allocator,
	stores:    map[typeid]^Store_Header,
	counter:   Entity,
}


// An internal header to help us manage the raw dynamic arrays
Store_Header :: struct {
	// Points to [dynamic]T
	instances: rawptr,
	// list in the same order as in instances
	entities:  [dynamic]Entity,
	sparse:    map[Entity]int,
	type_size: int,
}

add :: proc {
	add_trait_to_entity,
	add_trait_to_world,
	add_trait_2,
	add_trait_3,
	add_trait_4,
	add_trait_5,
}

get :: proc {
	get_trait,
	get_store,
}

make_world :: proc(allocator := context.allocator) -> World {
	return World {
		allocator = allocator, //
		stores    = make(map[typeid]^Store_Header, allocator),
	}
}

make_entity :: proc(world: ^World) -> Entity {
	id := world.counter
	world.counter += 1

	return id
}

destroy :: proc(world: ^World) {
	for _, store in world.stores {
		instances := (^[dynamic]any)(store.instances)
		delete(instances^)
		free(instances, world.allocator)
		delete(store.entities)
		delete(store.sparse)
		free(store, world.allocator)
	}
}

// User-facing API to "register" a component type
add_trait_to_world :: proc(world: ^World, $T: typeid) {
	store := new(Store_Header, world.allocator)

	instances := new([dynamic]T, world.allocator)
	instances^ = make([dynamic]T, world.allocator)
	store.instances = rawptr(instances)
	store.type_size = size_of(T)
	store.sparse = make(map[Entity]int, world.allocator)
	store.entities = make([dynamic]Entity, world.allocator)

	world.stores[T] = store
}

remove :: proc(world: ^World, entity: Entity, $T: typeid) {
	store, ok := world.stores[T]
	if !ok do panic(fmt.tprintf("no such trait type: %v", typeid_of(T)))

	index, found := store.sparse[entity]
	if !found do return // it's already been removed

	instances := (^[dynamic]T)(store.instances)
	last_index := len(instances) - 1

	// 1. Get the ID of the entity sitting at the very end
	last_entity := store.entities[last_index]

	// 2. Move the last data into the current slot (for both arrays)
	instances[index] = instances[last_index]
	store.entities[index] = store.entities[last_index]

	// 3. Update the map so the 'moved' entity knows its new home
	store.sparse[last_entity] = index

	// 4. Chop off the tail
	pop(instances)
	pop(&store.entities)
	delete_key(&store.sparse, entity)
}

add_trait_to_entity :: proc(world: ^World, entity: Entity, data: $T) {
	store, has_store := world.stores[typeid_of(T)]

	if !has_store {
		add_trait_to_world(world, T)
		store = world.stores[typeid_of(T)]
	}

	// Cast the rawptr back to a pointer to a dynamic array of T
	instances := (^[dynamic]T)(store.instances)

	append(instances, data)
	append(&store.entities, entity)
	store.sparse[entity] = len(instances) - 1
}


get_trait :: proc(world: World, entity: Entity, $T: typeid) -> (^T, bool) {
	store, ok := world.stores[T]
	if !ok do return nil, false

	idx, found := store.sparse[entity]
	if !found do return nil, false

	instances := (^[dynamic]T)(store.instances)
	return &instances[idx], true
}

get_store :: proc(world: ^World, $T: typeid) -> ^Store_Header {
	store, ok := world.stores[T]

	if !ok {
		log.debug("trait type not registered: %v", T, ", adding...")
		add_trait_to_world(world)
		store = world.stores[T]
	}

	return store
}
