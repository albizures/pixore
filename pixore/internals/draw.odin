package pixore_internals

import "../helpers"
import t "../traits"
import "core:log"
import rl "vendor:raylib"


draw_with_traits :: proc(world: ^t.World, id: t.Entity) {
	if border, has_border := t.get_trait(world, id, Border); has_border {
		draw_border(world, border^, id)
	}

	if background, has_background := t.get_trait(world, id, Background); has_background {
		draw_background(world, background^, id)
	}

	if children, has_children := t.get_trait(world, id, Children); has_children {
		for child in children.entities {
			draw_with_traits(world, child)
		}
	}
}

draw_border :: proc(world: ^t.World, border: Border, entity: t.Entity) {
	rect_ptr := t.expect_trait(world, entity, Pos, "Border trait expects position")
	anchor := get_anchor(world, entity)

	// clone the rect so we don't modify the original
	rect := rect_ptr^

	parent_offset := get_parent_offset(world, entity)

	width := f32(border.width)
	helpers.add_vec_to_rect(parent_offset, &rect)
	if border.kind == .Outside {
		rect.x -= width
		rect.y -= width
		rect.width += width * 2
		rect.height += width * 2
	}

	rl.DrawRectangleLinesEx(
		{rect.x - anchor.x, rect.y - anchor.y, rect.width, rect.height},
		width,
		border.color,
	)
}

draw_background :: proc(world: ^t.World, border: Background, entity: t.Entity) {
	rect_ptr := t.expect_trait(world, entity, Pos, "Background trait expects position")
	anchor := get_anchor(world, entity)

	// clone the rect so we don't modify the original
	rect := rect_ptr^

	parent_offset := get_parent_offset(world, entity)

	rl.DrawRectanglePro(
		{rect.x + parent_offset.x, rect.y + parent_offset.y, rect.width, rect.height},
		anchor,
		0,
		border.color,
	)
}

get_parent_offset :: proc(world: ^t.World, entity: t.Entity) -> rl.Vector2 {
	position, has_position := t.get_trait(world, entity, Position_Type)
	if !has_position || position^ == .Absolute {
		return rl.Vector2{0, 0}
	}

	parent, has_parent := t.get_trait(world, entity, Parent)
	if !has_parent {
		if position^ == .Relative {
			panic("Child with relative position but without parent")
		}

		return rl.Vector2{0, 0}
	}

	rect := t.expect_trait(
		world,
		parent.entity,
		Pos,
		"Parent with relative child needs to have a position",
	)

	return {rect.x, rect.y} + get_parent_offset(world, parent.entity)
}
