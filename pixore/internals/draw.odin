package pixore_internals

import t "../traits"
import rl "vendor:raylib"

draw_with_traits :: proc(traits: []t.Trait) {
	for trait in traits {
		#partial switch v in trait {
		case t.Border:
			pos := t.expect_trait(traits, t.Pos, "Border trait expects position")
			size := t.expect_trait(traits, t.Size, "Border trait expects size")
			anchor := t.find_trait(traits, t.Anchor)
			draw_border(v, pos, size, anchor)
		case t.Background:
			pos := t.expect_trait(traits, t.Pos, "Border trait expects position")
			size := t.expect_trait(traits, t.Size, "Border trait expects size")
			anchor := t.find_trait(traits, t.Anchor)
			draw_background(v, pos, size, anchor)
		case t.Margin, t.Padding, t.Pos, t.Size:
		// ignore they don't do anything by themselves
		case:
			panic("Trait not implemented")
		}
	}
}

draw_border :: proc(border: t.Border, pos: t.Pos, size: t.Size, anchor: Maybe(t.Anchor)) {
	start: rl.Vector2 = pos.value
	size: rl.Vector2 = size.value
	width := f32(border.width)

	if border.kind == .Outside {
		start -= width
		size += width * 2
	}

	value, ok := anchor.?
	anchor := value.value if ok else {0, 0}

	rl.DrawRectangleLinesEx(
		{start.x + anchor.x, start.y + anchor.y, size.x, size.y},
		width,
		border.color,
	)
}


draw_background :: proc(border: t.Background, pos: t.Pos, size: t.Size, anchor: Maybe(t.Anchor)) {
	start: rl.Vector2 = pos.value
	size: rl.Vector2 = size.value
	value, ok := anchor.?
	anchor := value.value if ok else {0, 0}

	rl.DrawRectanglePro({start.x, start.y, size.x, size.y}, anchor, 0, border.color)
}
