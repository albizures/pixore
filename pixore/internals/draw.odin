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
		case t.Margin, t.Padding, t.Pos, t.Size, t.Rec, t.Parent, t.Position:
		// ignore they don't do anything by themselves
		case:
			panic(fmt.tprintln("Trait not implemented:", trait))
		}
	}
}

draw_border :: proc(border: t.Border, traits: []t.Trait) {
	rec_trait := t.expect_trait(traits, t.Rec, "Border trait expects rec")
	anchor := t.get_anchor(traits)

	parent_offset := get_parent_offset(traits)

	width := f32(border.width)
	rec := rec_trait.value
	if border.kind == .Outside {
		rec.x += parent_offset.x - width
		rec.y += parent_offset.y - width
		rec.width += width * 2
		rec.height += width * 2
	}

	rl.DrawRectangleLinesEx(
		{rec.x - anchor.x, rec.y - anchor.y, rec.width, rec.height},
		width,
		border.color,
	)
}

draw_background :: proc(border: t.Background, traits: []t.Trait) {
	rec_trait := t.expect_trait(traits, t.Rec, "Background trait expects rec")
	anchor := t.get_anchor(traits)

	parent_offset := get_parent_offset(traits)

	rec := rec_trait.value

	rl.DrawRectanglePro(
		{rec.x + parent_offset.x, rec.y + parent_offset.y, rec.width, rec.height},
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
		t.Rec,
		"Parent with relative child needs to have a rec",
	)

	rec := rec_trait.value

	return {rec.x, rec.y} + get_parent_offset(parent_traits.traits)
}
