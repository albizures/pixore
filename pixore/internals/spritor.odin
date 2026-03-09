package pixore_internals

import "../helpers"
import "../traits"
import "core:log"
import "core:mem"
import rl "vendor:raylib"

Status :: enum {
	Uninitialized,
	Closed,
	Open,
}

Palette_Grid :: struct {
	traits: [dynamic]traits.Trait,
	cols:   u8,
	colors: [dynamic]Grid_Color,
}

Grid_Color :: struct {
	traits: [dynamic]traits.Trait,
	color:  rl.Color,
}

Canvas :: struct {
	traits: [dynamic]traits.Trait,
	// the scale of the sprite
	scale:  int,
	// the offset of the canvas from the top-left corner of the window
	offset: rl.Vector2,
}

Spritor_Child :: union #no_nil {
	Palette_Grid,
	Canvas,
}

// spritor is the union of sprite and editor together 😉
Spritor :: struct {
	arena:            mem.Arena,
	allocator:        mem.Allocator,
	status:           Status,
	last_press_time:  f64,
	// the time between two interactions to be considered a double click
	limit_press_rate: f64,
	traits:           [dynamic]traits.Trait,
	children:         [10]Spritor_Child,
}

PADDING: f32 : 2

init_spritor :: proc(spritor: ^Spritor) {
	// maybe it's a good idea to check the size of the palette,
	// since currently it's the only child that can grow.
	backing_buffer, err := mem.alloc_bytes(50 * mem.Kilobyte)
	if err != nil {
		panic("Unable to allocate memory for the spritior")
	}

	mem.arena_init(&spritor.arena, backing_buffer)
	spritor.allocator = mem.arena_allocator(&spritor.arena)

	spritor.traits = make([dynamic]traits.Trait, spritor.allocator)

	win_x, win_y := win_size()
	PADDING_TWO := PADDING * 2

	// spritor traits
	append(
		&spritor.traits,
		traits.Rect{PADDING, PADDING, f32(win_x) - PADDING_TWO, f32(win_y) - PADDING_TWO},
	)
	append(&spritor.traits, traits.Background{color = rl.BEIGE})
	append(
		&spritor.traits,
		traits.Border{color = rl.BLACK, width = 1, kind = .Outside, direction = .Full},
	)

	// spritor chidren
	spritor.children[0] = new_canvas(spritor^)
	spritor.children[1] = new_palette_grid(spritor^)

}

new_spritor :: proc() -> Spritor {
	return Spritor{limit_press_rate = 0.25}
}

open_spritor :: proc(spritor: ^Spritor) {
	if spritor.status == .Uninitialized {
		init_spritor(spritor)
	}

	spritor.status = .Open
}

close_spritor :: proc(spritor: ^Spritor) {
	spritor.status = .Closed

	used_space := spritor.arena.offset
	remaining := len(spritor.arena.data) - spritor.arena.offset
	log.warn("Used space: %d, Remaining space: %d", used_space, remaining)

}

uninit_spritor :: proc(spritor: ^Spritor) {
	spritor.status = .Uninitialized

	mem.arena_free_all(&spritor.arena)
}

update_spritor :: proc(spritor: ^Spritor) {
	if is_key_pressed(.PERIOD) {
		current_time := rl.GetTime()

		if current_time - spritor.last_press_time < spritor.limit_press_rate {
			if spritor.status != .Open {
				open_spritor(spritor)
			} else {
				close_spritor(spritor)
			}
			// Reset to 0 so a third click doesn't trigger another "double" press immediately
			spritor.last_press_time = 0
		} else {
			spritor.last_press_time = current_time
		}
	}

	if spritor.status == .Open {
		rect := traits.expect_trait(spritor.traits[:], traits.Rect, "Spritor is missng a rect")

		if rl.CheckCollisionPointRec(rl.GetMousePosition(), rect) {
			//
		}
	}
}

draw_spritor :: proc(spritor: Spritor) {
	if spritor.status != .Open {
		return
	}
	draw_with_traits(spritor.traits[:])
	for child in spritor.children {
		if traits, ok := get_child_traits(child).?; ok {
			draw_with_traits(traits, spritor.traits[:])
		}

		if grid, ok := child.(Palette_Grid); ok {
			draw_palette_grid(grid)
		}

		if canvas, ok := child.(Canvas); ok {
			draw_canvas(canvas)
		}
	}
}

draw_canvas :: proc(canvas: Canvas) {
	p := (^Pixore)(context.user_ptr)

	offset := get_parent_offset(canvas.traits[:])
	rect := traits.expect_trait_ptr(canvas.traits[:], traits.Rect, "Canvas is missing a rect")
	helpers.add_rect_to_vec(rect^, &offset)

	pixel := rl.Rectangle {
		width  = f32(canvas.scale),
		height = f32(canvas.scale),
	}

	size := f32(p.sprite.size) / f32(canvas.scale)
	limit: rl.Vector2 = canvas.offset + f32(canvas.scale)
	start := int(helpers.get_grid_index(canvas.offset.x, canvas.offset.y, size))
	end := int(helpers.get_grid_index(limit.x, limit.y, size))

	for color_index, index in p.sprite.data[start:end] {
		color := get_color(int(color_index))

		x, y := helpers.get_grid_cell(index, int(p.sprite.size))

		pixel.x = f32(x * canvas.scale) + offset.x
		pixel.y = f32(y * canvas.scale) + offset.y

		rl.DrawRectangleRec(pixel, color)
	}
}

draw_palette_grid :: proc(grid: Palette_Grid) {
	for color, index in grid.colors {
		x, y := helpers.get_grid_cell(index, int(grid.cols))
		rect := traits.expect_trait_ptr(
			color.traits[:],
			traits.Rect,
			"Palette Grid is missing a rect",
		)

		rect.x = f32(x * COLOR_SIZE)
		rect.y = f32(y * COLOR_SIZE)
		draw_with_traits(color.traits[:], grid.traits[:])
	}
}

get_child_traits :: proc(child: Spritor_Child) -> Maybe([]traits.Trait) {
	switch c in child {
	case Palette_Grid:
		return c.traits[:]
	case Canvas:
		return c.traits[:]
	}

	return nil
}

new_canvas :: proc(spritor: Spritor) -> Canvas {
	canvas := Canvas {
		traits = make([dynamic]traits.Trait, spritor.allocator),
		scale  = 8,
		offset = {0, 0},
	}

	append(&canvas.traits, traits.Rect{x = 2, y = 2, width = 64, height = 64})
	append(&canvas.traits, traits.Position.Relative)
	append(&canvas.traits, traits.Border{color = rl.BLACK, direction = .Full, width = 1})
	append(&canvas.traits, traits.Parent{traits = spritor.traits[:]})

	append(&canvas.traits, traits.Background{color = rl.BROWN})

	return canvas
}

PALETTE_COLS :: 4
COLOR_SIZE :: 12

new_palette_grid :: proc(spritor: Spritor) -> Palette_Grid {
	p := (^Pixore)(context.user_ptr)
	grid := Palette_Grid {
		traits = make([dynamic]traits.Trait, spritor.allocator),
		cols   = PALETTE_COLS,
		colors = make([dynamic]Grid_Color),
	}

	size: f32 = PALETTE_COLS * COLOR_SIZE

	append(&grid.traits, traits.Rect{x = 70, y = 2, width = size, height = size})
	append(&grid.traits, traits.Position.Relative)
	append(&grid.traits, traits.Border{color = rl.BLACK, direction = .Full, width = 1})
	append(&grid.traits, traits.Parent{traits = spritor.traits[:]})

	append(&grid.traits, traits.Background{color = rl.BROWN})


	for color in p.palette {
		new_color := Grid_Color {
			traits = make([dynamic]traits.Trait, spritor.allocator),
			color  = color,
		}

		append(
			&new_color.traits,
			traits.Rect{x = 0, y = 0, width = COLOR_SIZE, height = COLOR_SIZE},
		)
		append(&new_color.traits, traits.Background{color = color})
		append(&new_color.traits, traits.Position.Relative)
		append(&new_color.traits, traits.Parent{traits = grid.traits[:]})

		append(&grid.colors, new_color)

	}

	return grid
}
