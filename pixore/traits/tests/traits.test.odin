package traits_test

import traits ".."
import "core:mem"
import "core:testing"

Position :: struct {
	x, y: f32,
}

Velocity :: struct {
	dx, dy: f32,
}

@(test)
test_add_trait_to_world :: proc(t: ^testing.T) {
	world := traits.make_world(context.temp_allocator)
	defer traits.destroy(&world)

	traits.add(&world, Position)

	store, ok := world.stores[Position]
	testing.expect(t, ok, "Position trait should be registered in the world")
	if ok {
		testing.expect(
			t,
			store.type_size == size_of(Position),
			"Store type_size should match Position size",
		)
		testing.expect(t, store.instances != nil, "Store instances should be allocated")
		// testing.expect(t, store.sparse != nil, "Store sparse map should be allocated")
		// testing.expect(t, store.entities != nil, "Store entities array should be allocated")
	}
}

@(test)
test_add_trait_to_entity :: proc(t: ^testing.T) {
	world := traits.make_world(context.temp_allocator)
	defer traits.destroy(&world)

	traits.add(&world, Position)

	entity_id := traits.Entity(1)
	pos := Position {
		x = 10,
		y = 20,
	}

	traits.add(&world, entity_id, pos)

	store := world.stores[Position]

	index, found := store.sparse[entity_id]
	testing.expect(t, found, "Entity should be in sparse map")
	testing.expect(t, index == 0, "Entity should be at index 0")

	testing.expect(t, len(store.entities) == 1, "Entities array should have length 1")
	testing.expect(
		t,
		store.entities[0] == entity_id,
		"Entities array should contain the correct entity_id",
	)

	instances := (^[dynamic]Position)(store.instances)
	testing.expect(t, len(instances^) == 1, "Instances array should have length 1")
	testing.expect(
		t,
		instances^[0].x == 10 && instances^[0].y == 20,
		"Instances array should contain the correct data",
	)
}

@(test)
test_get_trait :: proc(t: ^testing.T) {
	world := traits.make_world(context.temp_allocator)
	defer traits.destroy(&world)

	traits.add(&world, Position)

	entity_id := traits.Entity(1)
	pos := Position {
		x = 15,
		y = 25,
	}
	traits.add(&world, entity_id, pos)

	retrieved_pos, ok := traits.get(&world, entity_id, Position)
	testing.expect(t, ok, "Should successfully retrieve trait")
	if ok {
		testing.expect(
			t,
			retrieved_pos.x == 15 && retrieved_pos.y == 25,
			"Retrieved trait should have correct values",
		)

		// Modify to check if it's a pointer to the actual data
		retrieved_pos.x = 30
		retrieved_pos2, _ := traits.get(&world, entity_id, Position)
		testing.expect(
			t,
			retrieved_pos2.x == 30,
			"Modifying retrieved trait should update the original data",
		)
	}

	// Test missing entity
	_, ok2 := traits.get(&world, traits.Entity(2), Position)
	testing.expect(t, !ok2, "Should not retrieve trait for missing entity")

	// Test missing trait type
	_, ok3 := traits.get(&world, entity_id, Velocity)
	testing.expect(t, !ok3, "Should not retrieve missing trait type")
}

@(test)
test_remove_trait :: proc(t: ^testing.T) {
	world := traits.make_world(context.temp_allocator)
	defer traits.destroy(&world)

	traits.add(&world, Position)

	e1 := traits.Entity(1)
	e2 := traits.Entity(2)
	e3 := traits.Entity(3)

	traits.add(&world, e1, Position{1, 1})
	traits.add(&world, e2, Position{2, 2})
	traits.add(&world, e3, Position{3, 3})

	store := world.stores[Position]
	instances := (^[dynamic]Position)(store.instances)

	testing.expect(t, len(instances^) == 3, "Should have 3 instances initially")

	// Remove middle element to test swap-and-pop
	traits.remove(&world, e2, Position)

	testing.expect(t, len(instances^) == 2, "Should have 2 instances after removal")
	testing.expect(t, len(store.entities) == 2, "Should have 2 entities after removal")

	// e3 should have been swapped into e2's place (index 1)
	idx_e3, found_e3 := store.sparse[e3]
	testing.expect(t, found_e3, "e3 should still be in sparse map")
	testing.expect(t, idx_e3 == 1, "e3 should be at index 1 after swap")
	testing.expect(t, store.entities[1] == e3, "e3 should be at index 1 in entities array")
	testing.expect(
		t,
		instances^[1].x == 3 && instances^[1].y == 3,
		"e3 data should be at index 1 in instances array",
	)

	// e1 should be unchanged (index 0)
	idx_e1, found_e1 := store.sparse[e1]
	testing.expect(t, found_e1, "e1 should still be in sparse map")
	testing.expect(t, idx_e1 == 0, "e1 should be at index 0")

	// e2 should be removed
	_, found_e2 := store.sparse[e2]
	testing.expect(t, !found_e2, "e2 should be removed from sparse map")

	retrieved_pos_e2, ok_e2 := traits.get(&world, e2, Position)
	testing.expect(t, !ok_e2, "Should not be able to retrieve e2's Position")

	// Remove last element (e3, now at index 1)
	traits.remove(&world, e3, Position)
	testing.expect(t, len(instances^) == 1, "Should have 1 instance after second removal")
	testing.expect(t, store.entities[0] == e1, "e1 should still be at index 0")
	testing.expect(
		t,
		instances^[0].x == 1 && instances^[0].y == 1,
		"e1 data should still be correct",
	)
}
