package pixore_internals

import "../helpers"
import "../traits"
import rl "vendor:raylib"

Event_Kind :: enum {
	Color_Select,
}

Event_Header :: struct {
	kind: Event_Kind,
}

On_Click :: struct {
	payload:  rawptr,
	callback: proc(raw_data: rawptr),
}

event_capturing :: proc(p: ^Pixore, id: traits.Entity, pos: rl.Vector2) {
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
			event_capturing(p, traits.Entity(child), pos)
		}
	}


	click, has_on_click := traits.get_trait(p.world, id, On_Click)

	if has_on_click {
		click.callback(click.payload)
	}
}
