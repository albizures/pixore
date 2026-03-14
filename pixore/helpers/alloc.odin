package helpers

import "core:log"
import mem "core:mem"

Arena :: struct {
	core_arena: mem.Arena,
	allocator:  mem.Allocator,
}

init_arena :: proc(arena: ^Arena, size: int, loc := #caller_location) {
	backing_buffer, err := mem.alloc_bytes(size)
	assert(err == .None, "Unable to allocate memory for the spritor", loc = loc)

	mem.arena_init(&arena.core_arena, backing_buffer)
	arena.allocator = mem.arena_allocator(&arena.core_arena)
}

print_remaining :: proc(arena: ^Arena, name: string, loc := #caller_location) {
	used_space := arena.core_arena.offset
	remaining := len(arena.core_arena.data) - arena.core_arena.offset
	// If remaining space is less than 5% of the arena, emit a warning
	total := len(arena.core_arena.data)
	if total > 0 {
		percent := (remaining * 100) / total
		if percent < 5 {
			log.warnf(
				"Arena %s low remaining: %d bytes (%d%%)",
				name,
				remaining,
				percent,
				location = loc,
			)
		}
	}
	log.infof(
		"Used space: %d, Remaining space: %d of %s",
		used_space,
		remaining,
		name,
		location = loc,
	)
}
