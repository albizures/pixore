package pixore_internals

import t "../traits"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

draw_with_traits :: proc(traits: []t.Trait, parent_traits: Maybe([]t.Trait) = nil) {
	for trait in traits {
		#partial switch v in trait {
		case t.Border:
			draw_border(v, traits)
		case t.Background:
			draw_background(v, traits)
		case t.Margin, t.Padding, t.Pos, t.Size, t.Rect, t.Parent, t.Position:
		// ignore they don't do anything by themselves
		case:
			panic(fmt.tprintln("Trait not implemented:", trait))
		}
	}
}

draw_border :: proc(border: t.Border, traits: []t.Trait) {
	rect_trait := t.expect_trait(traits, t.Rect, "Border trait expects rect")
	anchor := t.get_anchor(traits)

	parent_offset := get_parent_offset(traits)

	width := f32(border.width)
	rect := rect_trait.value
	if border.kind == .Outside {
		rect.x += parent_offset.x - width
		rect.y += parent_offset.y - width
		rect.width += width * 2
		rect.height += width * 2
	}

	rl.DrawRectangleLinesEx(
		{rect.x - anchor.x, rect.y - anchor.y, rect.width, rect.height},
		width,
		border.color,
	)
}

draw_background :: proc(border: t.Background, traits: []t.Trait) {
	rect_trait := t.expect_trait(traits, t.Rect, "Background trait expects rect")
	anchor := t.get_anchor(traits)

	parent_offset := get_parent_offset(traits)

	rect := rect_trait.value

	rl.DrawRectanglePro(
		{rect.x + parent_offset.x, rect.y + parent_offset.y, rect.width, rect.height},
		anchor,
		0,
		border.color,
	)
}

get_parent_offset :: proc(traits: []t.Trait) -> rl.Vector2 {
	maybe_parent := t.find_trait(traits, t.Parent)
	position_trait := t.find_trait(traits, t.Position)

	position, has_position := position_trait.?
	if !has_position || position == .Absolute {
		return rl.Vector2{0, 0}
	}

	parent_traits, has_parent := maybe_parent.?
	if !has_parent {
		if position == .Relative {
			panic("Child with relative position but without parent")
		}

		return rl.Vector2{0, 0}
	}


	rec_trait := t.expect_trait(
		parent_traits.traits,
		t.Rect,
		"Parent with relative child needs to have a rect",
	)

	rect := rec_trait.value

	return {rect.x, rect.y} + get_parent_offset(parent_traits.traits)
}
