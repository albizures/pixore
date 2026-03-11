package pixore_internals

import "../helpers"
import t "../traits"
import "core:debug/trace"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

draw_with_id :: proc(world: t.World, id: t.Entity_Id) {
	entity := t.get_entity(world, id)

	draw_with_traits(world, entity.traits[:])
}

draw_with_traits :: proc(world: t.World, traits: []t.Trait) {
	for trait in traits {
		#partial switch v in trait {
		case t.Border:
			draw_border(world, v, traits)
		case t.Background:
			draw_background(world, v, traits)
		case t.Child:
			draw_with_id(world, t.Entity_Id(v))
		case t.Margin,
		     t.Padding,
		     t.Pos,
		     t.Size,
		     t.Rect,
		     t.Parent2,
		     t.Position,
		     t.Anchor,
		     t.On_Click,
		     t.Is_Mouse_Interactive:
		// ignore they don't do anything by themselves
		case:
			panic(fmt.tprintln("Trait not implemented in the drawing:", trait))
		}
	}
}

draw_border :: proc(world: t.World, border: t.Border, traits: []t.Trait) {
	rect := t.expect_trait(traits, t.Rect, "Border trait expects rect")
	anchor := t.get_anchor(traits[:])

	parent_offset := get_parent_offset(world, traits)

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

draw_background :: proc(world: t.World, border: t.Background, traits: []t.Trait) {
	rect := t.expect_trait(traits, t.Rect, "Background trait expects rect")
	anchor := t.get_anchor(traits)

	parent_offset := get_parent_offset(world, traits)

	rl.DrawRectanglePro(
		{rect.x + parent_offset.x, rect.y + parent_offset.y, rect.width, rect.height},
		anchor,
		0,
		border.color,
	)
}

get_parent_offset :: proc(world: t.World, traits: []t.Trait) -> rl.Vector2 {
	maybe_parent := t.find_trait(traits, t.Parent2)
	position_trait := t.find_trait(traits, t.Position)

	position, has_position := position_trait.?
	if !has_position || position == .Absolute {
		return rl.Vector2{0, 0}
	}

	parent_id, has_parent := maybe_parent.?
	if !has_parent {
		if position == .Relative {
			panic("Child with relative position but without parent")
		}

		return rl.Vector2{0, 0}
	}

	parent_traits := t.get_traits(world, t.Entity_Id(parent_id))


	rect := t.expect_trait(
		parent_traits,
		t.Rect,
		"Parent with relative child needs to have a rect",
	)

	return {rect.x, rect.y} + get_parent_offset(world, parent_traits)
}
