package pixore_internals

import "../helpers"
import "../traits"
import "core:log"
import rl "vendor:raylib"

handle_interactions :: proc(p: ^Pixore) {
	root_traits := traits.get_traits(p.world, p.root_entity)
	rect := traits.expect_trait(root_traits, traits.Rect, "Spritor is missng a rect")

	if is_mouse_pressed(.LEFT) {
		deep_interactions(p, p.root_entity, get_mouse_position())

	}
}

deep_interactions :: proc(p: ^Pixore, id: traits.Entity_Id, pos: rl.Vector2) {
	curr_traits := traits.get_traits(p.world, id)
	maybe_rect := traits.find_trait(curr_traits, traits.Rect)

	rect, has_rect := maybe_rect.?

	if !has_rect {
		return
	}

	offset := get_parent_offset(p.world, curr_traits)
	real_rect := rl.Rectangle(rect)
	helpers.add_vec_to_rect(offset, &real_rect)

	if !rl.CheckCollisionPointRec(pos, real_rect) {
		return
	}

	children := traits.get_all(p.world, id, traits.Child)

	for child in children {
		deep_interactions(p, traits.Entity_Id(child), pos)
	}

	click, has_on_click := traits.find_trait(curr_traits, traits.On_Click).?

	if has_on_click {
		click.callback(nil)
	}
}
