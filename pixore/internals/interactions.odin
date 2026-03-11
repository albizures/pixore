package pixore_internals

import "../helpers"
import "../traits"
import rl "vendor:raylib"

handle_interactions :: proc(p: ^Pixore) {
	rect := traits.expect_trait(p.world, p.root_entity, Pos, "Spritor is missng a position")

	if is_mouse_pressed(.LEFT) {
		deep_interactions(p, p.root_entity, get_mouse_position())
	}
}

deep_interactions :: proc(p: ^Pixore, id: traits.Entity_Id, pos: rl.Vector2) {
	rect, has_rect := traits.get_trait(p.world, id, Pos)

	if !has_rect {
		return
	}

	offset := get_parent_offset(p.world, id)
	real_rect := rect.rect
	helpers.add_vec_to_rect(offset, &real_rect)

	if !rl.CheckCollisionPointRec(pos, real_rect) {
		return
	}

	children, has_children := traits.get_trait(p.world, id, Children)

	if has_children {
		for child in children.entities {
			deep_interactions(p, traits.Entity_Id(child), pos)
		}
	}


	click, has_on_click := traits.get_trait(p.world, id, On_Click)

	if has_on_click {
		click.callback(nil)
	}
}
