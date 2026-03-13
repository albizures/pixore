package helpers

import "core:log"
import mem "core:mem"

Arena :: struct {
	core_arena: mem.Arena,
	allocator:  mem.Allocator,
}

init_arena :: proc(arena: ^Arena, size: int) {
	backing_buffer, err := mem.alloc_bytes(size)
	if err != nil {
		panic("Unable to allocate memory for the spritior")
	}

	mem.arena_init(&arena.core_arena, backing_buffer)
	arena.allocator = mem.arena_allocator(&arena.core_arena)
}

print_remaining :: proc(arena: ^Arena, name: string, loc := #caller_location) {
	used_space := arena.core_arena.offset
	remaining := len(arena.core_arena.data) - arena.core_arena.offset
	log.warnf(
		"Used space: %d, Remaining space: %d of %s",
		used_space,
		remaining,
		name,
		location = loc,
	)
}
