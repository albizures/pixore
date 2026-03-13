package pixore_internals

import "../common"
import "../events"
import "../helpers"
import "../traits"
import "core:log"
import "core:mem"
import rl "vendor:raylib"

SPRITOR_ARENA_SIZE: int = 1 * mem.Kilobyte
PADDING: f32 : 2
PALETTE_COLS :: 4
COLOR_SIZE :: 12

Editor_Status :: common.Editor_Status
Spritor :: common.Spritor

init_spritor :: proc(p: ^Pixore) {
	spritor := &p.editors.spritor

	helpers.init_arena(spritor, SPRITOR_ARENA_SIZE)
	defer helpers.print_remaining(&p.systems, "systems")
	defer helpers.print_remaining(spritor, "spritor")

	win_x, win_y := win_size()

	PADDING_TWO := PADDING * 2
	spritor.columns = PALETTE_COLS
	spritor.canvas_id = new_canvas(p)
	palette_id := new_palette_grid(p)
	spritor.spritor_id = traits.create(&p.systems.world)
	traits.add(
		&p.systems.world,
		spritor.spritor_id,
		Pos{rect = {PADDING, PADDING, f32(win_x) - PADDING_TWO, f32(win_y) - PADDING_TWO}},
		Background{color = rl.BEIGE},
		Border{color = rl.BLACK, width = 1, kind = .Outside, direction = .Full},
	)

	add_child(&p.systems.world, spritor.spritor_id, spritor.canvas_id, palette_id)

	spritor.scale = 8
	spritor.offset = {0, 0}

	add_child(&p.systems.world, p.systems.root_entity, spritor.spritor_id)

	log.info("Spritor id", spritor.spritor_id)
	log.info("Canvas id", spritor.canvas_id)
	log.info("Current color id", spritor.current_color_id)
	log.info("Color entities", spritor.color_entities)
}

create_spritor :: proc() -> Spritor {
	return Spritor{limit_press_rate = 0.25}
}

open_spritor :: proc(p: ^Pixore) {
	if p.editors.spritor.status == .Uninitialized {
		init_spritor(p)
	}

	p.editors.spritor.status = .Open
}

close_spritor :: proc(p: ^Pixore) {
	spritor := &p.editors.spritor
	spritor.status = .Closed

	helpers.print_remaining(spritor, "spritor")
}

uninit_spritor :: proc(spritor: ^Spritor) {
	spritor.status = .Uninitialized

	mem.arena_free_all(&spritor.arena.core_arena)
}

update_spritor :: proc(p: ^Pixore) {
	spritor := &p.editors.spritor
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
			p.systems.world,
			spritor.spritor_id,
			Pos,
			"Spritor is missing a position",
		)

		if is_mouse_pressed(.LEFT) && rl.CheckCollisionPointRec(get_mouse_position(), rect) {
			event_capturing(p, spritor.spritor_id, get_mouse_position())
		}
	}
}

draw_spritor :: proc(p: Pixore) {
	if p.editors.spritor.status != .Open {
		return
	}

	draw_with_traits(p.systems.world, p.editors.spritor.spritor_id)
	draw_canvas(p, p.editors.spritor)
}

draw_canvas :: proc(p: Pixore, spritor: Spritor) {
	offset := get_parent_offset(p.systems.world, spritor.canvas_id)
	rect := traits.expect_trait(
		p.systems.world,
		spritor.canvas_id,
		Pos,
		"Canvas is missing a position",
	)

	helpers.add_rect_to_vec(rect, &offset)

	pixel := rl.Rectangle {
		width  = f32(spritor.scale),
		height = f32(spritor.scale),
	}

	size := f32(p.resources.sprite.size) / f32(spritor.scale)
	limit := spritor.offset + f32(spritor.scale)
	start := int(helpers.get_grid_index(spritor.offset.x, spritor.offset.y, size))
	end := int(helpers.get_grid_index(limit.x, limit.y, size))

	for color_index, index in p.resources.sprite.data[start:end] {
		color := get_color(int(color_index))

		x, y := helpers.get_grid_cell(index, int(p.resources.sprite.size))

		pixel.x = f32(x * spritor.scale) + offset.x
		pixel.y = f32(y * spritor.scale) + offset.y

		rl.DrawRectangleRec(pixel, color)
	}
}

new_canvas :: proc(p: ^Pixore) -> traits.Entity {
	entity_id := traits.create(&p.systems.world)
	traits.add(
		&p.systems.world,
		entity_id,
		Pos{x = 2, y = 2, width = 64, height = 64},
		Position_Type.Relative,
		Border{color = rl.BLACK, direction = .Full, width = 1},
		Background{color = rl.BROWN},
	)

	return entity_id
}


new_palette_grid :: proc(p: ^Pixore) -> traits.Entity {
	spritor := &p.editors.spritor
	spritor.color_entities = make(
		[dynamic]traits.Entity,
		0,
		len(p.resources.palette),
		spritor.allocator,
	)
	size: f32 = PALETTE_COLS * COLOR_SIZE
	entity_id := traits.create(&p.systems.world)

	traits.add(
		&p.systems.world,
		entity_id,
		Pos{x = 70, y = 2, width = size, height = size},
		Position_Type.Relative,
		Border{color = rl.BLACK, direction = .Full, width = 1},
		Background{color = rl.BROWN},
	)

	rect := rl.Rectangle {
		x      = 0,
		y      = 0,
		width  = size,
		height = size,
	}

	for color, index in p.resources.palette {
		x, y := helpers.get_grid_cell(index, int(spritor.columns))

		entity_color_id := traits.create(&p.systems.world)

		append(&spritor.color_entities, entity_color_id)

		payload := new(Color_Select_Event)
		payload.header.kind = Event_Kind.Color_Select
		payload.pixore = p
		payload.color_index = index

		rect_x := f32(x * COLOR_SIZE)
		rect_y := f32(y * COLOR_SIZE)
		rect_width: f32 = COLOR_SIZE
		rect_height: f32 = COLOR_SIZE

		traits.add(
			&p.systems.world,
			entity_color_id,
			Pos{x = rect_x, y = rect_y, width = rect_width, height = rect_height},
			Position_Type.Relative,
			Background{color = color},
			On_Click{callback = on_color_click, payload = rawptr(payload)},
		)

		if p.state.selected_color == index {
			rect.x = rect_x
			rect.y = rect_y
			rect.width = rect_width
			rect.height = rect_height
		}

		add_child(&p.systems.world, entity_id, entity_color_id)
	}

	primary_color_entity_id := traits.create(&p.systems.world)
	traits.add(
		&p.systems.world,
		primary_color_entity_id,
		Pos{rect = rect},
		Position_Type.Relative,
		Border{kind = Border_Kind.Inside, width = 1, color = rl.BLACK},
		Border{kind = Border_Kind.Outside, width = 1, color = rl.WHITE},
	)

	add_child(&p.systems.world, entity_id, primary_color_entity_id)

	spritor.current_color_id = primary_color_entity_id

	return entity_id
}

get_entity_color_id :: proc(p: Pixore, color_index: int) -> traits.Entity {
	return p.editors.spritor.color_entities[color_index]
}

sync_selected_color :: proc(event: Color_Change) {
	p := event.pixore

	entity_id := get_entity_color_id(p^, p.state.selected_color)
	current_color_entity_id := p.editors.spritor.current_color_id

	target_pos := traits.expect_trait(
		p.systems.world,
		entity_id,
		Pos,
		"Missing position in color entity",
	)
	dest_pos := traits.expect_trait(
		p.systems.world,
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

	events.fire(p.systems.dispatcher, Color_Change{pixore = p, index = event.color_index})
}

Color_Select_Event :: struct {
	using header: Event_Header,
	pixore:       ^Pixore,
	color_index:  int,
}
