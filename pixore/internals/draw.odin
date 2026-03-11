package pixore_internals

import "../helpers"
import t "../traits"
import rl "vendor:raylib"


draw_with_traits :: proc(world: t.World2, id: t.Entity_Id) {
	if border, has_border := t.get_trait(world, id, t.Border); has_border {
		draw_border(world, border^, id)
	}

	if background, has_background := t.get_trait(world, id, t.Background); has_background {
		draw_background(world, background^, id)
	}

	if children, has_children := t.get_trait(world, id, t.Children); has_children {
		for child in children.entities {
			draw_with_traits(world, child)
		}
	}
}

draw_border :: proc(world: t.World2, border: t.Border, entity: t.Entity_Id) {
	rect_ptr := t.expect_trait(world, entity, t.Rect, "Border trait expects rect")
	anchor := t.get_anchor(world, entity)

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

draw_background :: proc(world: t.World2, border: t.Background, entity: t.Entity_Id) {
	rect_ptr := t.expect_trait(world, entity, t.Rect, "Background trait expects rect")
	anchor := t.get_anchor(world, entity)

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

get_parent_offset :: proc(world: t.World2, entity: t.Entity_Id) -> rl.Vector2 {
	position, has_position := t.get_trait(world, entity, t.Position)
	if !has_position || position^ == .Absolute {
		return rl.Vector2{0, 0}
	}

	parent_id, has_parent := t.get_trait(world, entity, t.Parent2)
	if !has_parent {
		if position^ == .Relative {
			panic("Child with relative position but without parent")
		}

		return rl.Vector2{0, 0}
	}

	rect := t.expect_trait(
		world,
		t.Entity_Id(parent_id^),
		t.Rect,
		"Parent with relative child needs to have a rect",
	)

	return {rect.x, rect.y} + get_parent_offset(world, t.Entity_Id(parent_id^))
}
