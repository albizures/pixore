package pixore_internals

import "../events"
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
	cols:                    u8,
	entity_id:               traits.Entity,
	current_color_entity_id: traits.Entity,
	color_entities:          [dynamic]traits.Entity,
}

Canvas :: struct {
	// the scale of the sprite
	scale:     int,
	// the offset of the canvas from the top-left corner of the window
	offset:    rl.Vector2,
	entity_id: traits.Entity,
}


// spritor is the union of sprite and editor together 😉
Spritor :: struct {
	arena:            mem.Arena,
	allocator:        mem.Allocator,
	status:           Status,
	last_press_time:  f64,
	// the time between two interactions to be considered a double click
	limit_press_rate: f64,
	canvas:           Canvas,
	palette:          Palette_Grid,
	entity_id:        traits.Entity,
}

PADDING: f32 : 2

init_spritor :: proc(p: ^Pixore) {
	spritor := &p.spritor

	// maybe it's a good idea to check the size of the palette,
	// since currently it's the only child that can grow.
	backing_buffer, err := mem.alloc_bytes(50 * mem.Kilobyte)
	if err != nil {
		panic("Unable to allocate memory for the spritior")
	}

	mem.arena_init(&p.spritor.arena, backing_buffer)
	spritor.allocator = mem.arena_allocator(&spritor.arena)

	// spritor.traits = make([dynamic]traits.Trait, spritor.allocator)
	canvas := new_canvas(p)
	palette := new_palette_grid(p)

	win_x, win_y := win_size()

	PADDING_TWO := PADDING * 2

	spritor.entity_id = traits.make_entity(&p.world)
	traits.add(
		&p.world,
		spritor.entity_id,
		Pos{rect = {PADDING, PADDING, f32(win_x) - PADDING_TWO, f32(win_y) - PADDING_TWO}},
		Background{color = rl.BEIGE},
		Border{color = rl.BLACK, width = 1, kind = .Outside, direction = .Full},
	)

	add_child(&p.world, spritor.entity_id, canvas.entity_id, palette.entity_id)

	spritor.canvas = canvas
	spritor.palette = palette

	add_child(&p.world, p.root_entity, spritor.entity_id)

	log.info("Spritor id", spritor.entity_id)
	log.info("Palette id", palette.entity_id)
	log.info("Canvas id", canvas.entity_id)
}

new_spritor :: proc() -> Spritor {
	return Spritor{limit_press_rate = 0.25}
}

open_spritor :: proc(p: ^Pixore) {
	if p.spritor.status == .Uninitialized {
		init_spritor(p)
	}

	p.spritor.status = .Open
}

close_spritor :: proc(p: ^Pixore) {
	spritor := &p.spritor
	spritor.status = .Closed

	used_space := spritor.arena.offset
	remaining := len(spritor.arena.data) - spritor.arena.offset
	log.warn("Used space: %d, Remaining space: %d", used_space, remaining)
}

uninit_spritor :: proc(spritor: ^Spritor) {
	spritor.status = .Uninitialized

	mem.arena_free_all(&spritor.arena)
}

update_spritor :: proc(p: ^Pixore) {
	spritor := &p.spritor
	if is_key_pressed(.PERIOD) {
		current_time := rl.GetTime()

		if current_time - spritor.last_press_time < spritor.limit_press_rate {
			if spritor.status != .Open {
				open_spritor(p)
			} else {
				close_spritor(p)
			}
			// Reset to 0 so a third click doesn't trigger another "double" press immediately
			spritor.last_press_time = 0
		} else {
			spritor.last_press_time = current_time
		}
	}

	if spritor.status == .Open {

		rect := traits.expect_trait(
			p.world,
			spritor.entity_id,
			Pos,
			"Spritor is missng a position",
		)

		if is_mouse_pressed(.LEFT) && rl.CheckCollisionPointRec(get_mouse_position(), rect) {
			event_capturing(p, spritor.entity_id, get_mouse_position())
		}
	}
}

draw_spritor :: proc(p: Pixore) {
	if p.spritor.status != .Open {
		return
	}

	draw_with_traits(p.world, p.spritor.entity_id)
	draw_canvas(p, p.spritor.canvas)
}

draw_canvas :: proc(p: Pixore, canvas: Canvas) {
	offset := get_parent_offset(p.world, canvas.entity_id)
	rect := traits.expect_trait(p.world, canvas.entity_id, Pos, "Canvas is missing a position")

	helpers.add_rect_to_vec(rect, &offset)

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

new_canvas :: proc(p: ^Pixore) -> Canvas {
	canvas := Canvas {
		scale  = 8,
		offset = {0, 0},
	}

	entity_id := traits.make_entity(&p.world)
	traits.add(
		&p.world,
		entity_id,
		Pos{x = 2, y = 2, width = 64, height = 64},
		Position_Type.Relative,
		Border{color = rl.BLACK, direction = .Full, width = 1},
		Background{color = rl.BROWN},
	)

	canvas.entity_id = entity_id

	return canvas
}

PALETTE_COLS :: 4
COLOR_SIZE :: 12

new_palette_grid :: proc(p: ^Pixore) -> Palette_Grid {
	grid := Palette_Grid {
		cols           = PALETTE_COLS,
		color_entities = make([dynamic]traits.Entity),
	}

	size: f32 = PALETTE_COLS * COLOR_SIZE
	entity_id := traits.make_entity(&p.world)

	traits.add(
		&p.world,
		entity_id,
		Pos{x = 70, y = 2, width = size, height = size},
		Position_Type.Relative,
		Border{color = rl.BLACK, direction = .Full, width = 1},
		Background{color = rl.BROWN},
	)

	grid.entity_id = entity_id
	rect := rl.Rectangle {
		x      = 0,
		y      = 0,
		width  = size,
		height = size,
	}

	for color, index in p.palette {
		x, y := helpers.get_grid_cell(index, int(grid.cols))

		entity_color_id := traits.make_entity(&p.world)

		append(&grid.color_entities, entity_color_id)

		payload := new(Color_Select_Event)
		payload.header.kind = Event_Kind.Color_Select
		payload.pixore = p
		payload.color_index = index

		rect_x := f32(x * COLOR_SIZE)
		rect_y := f32(y * COLOR_SIZE)
		rect_width: f32 = COLOR_SIZE
		rect_height: f32 = COLOR_SIZE

		traits.add(
			&p.world,
			entity_color_id,
			Pos{x = rect_x, y = rect_y, width = rect_width, height = rect_height},
			Position_Type.Relative,
			Background{color = color},
			On_Click{callback = on_color_click, payload = rawptr(payload)},
		)

		if p.selected_color == index {
			rect.x = rect_x
			rect.y = rect_y
			rect.width = rect_width
			rect.height = rect_height
		}

		add_child(&p.world, entity_id, entity_color_id)
	}

	primary_color_entity_id := traits.make_entity(&p.world)
	traits.add(
		&p.world,
		primary_color_entity_id,
		Pos{rect = rect},
		Position_Type.Relative,
		Border{kind = Border_Kind.Inside, width = 1, color = rl.BLACK},
		Border{kind = Border_Kind.Outside, width = 1, color = rl.WHITE},
	)

	add_child(&p.world, entity_id, primary_color_entity_id)

	grid.current_color_entity_id = primary_color_entity_id

	return grid
}

get_entity_color_id :: proc(p: Pixore, color_index: int) -> traits.Entity {
	return p.spritor.palette.color_entities[color_index]
}

sync_selected_color :: proc(event: Color_Change) {
	p := event.pixore

	entity_id := get_entity_color_id(p^, p.selected_color)
	current_color_entity_id := p.spritor.palette.current_color_entity_id

	target_pos := traits.expect_trait(p.world, entity_id, Pos, "Missing position in color entity")
	dest_pos := traits.expect_trait(
		p.world,
		current_color_entity_id,
		Pos,
		"Missing position in current color entity",
	)

	dest_pos.x = target_pos.x
	dest_pos.y = target_pos.y
	dest_pos.width = COLOR_SIZE
	dest_pos.height = COLOR_SIZE
}

on_color_click :: proc(data: rawptr) {
	event := (^Color_Select_Event)(data)
	p := event.pixore

	events.fire(p.dispatcher, Color_Change{pixore = p, index = event.color_index})
}

Color_Select_Event :: struct {
	using header: Event_Header,
	pixore:       ^Pixore,
	color_index:  int,
}
