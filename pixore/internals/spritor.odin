package pixore_internals

import "../traits"
import "core:log"
import rl "vendor:raylib"

Status :: enum {
	Closed,
	Open,
}

// spritor is the word sprite and editor together 😉
Spritor :: struct {
	status:           Status,
	last_press_time:  f64,
	// the time between two interactions to be considered a double click
	limit_press_rate: f64,
	traits:           [dynamic]traits.Trait,
}

PADDING :: 2

init_spritor :: proc(spritor: ^Spritor) {
	spritor.limit_press_rate = 0.25
}

open_spritor :: proc(spritor: ^Spritor) {
	spritor.status = .Open
	spritor.traits = make([dynamic]traits.Trait)

	win_x, win_y := win_size()
	log.warn(win_x, win_y, rl.Vector2{f32(win_x), f32(win_y)} - (PADDING * 2))
	append(&spritor.traits, traits.Pos{value = {PADDING, PADDING}})
	append(
		&spritor.traits,
		traits.Size{value = rl.Vector2{f32(win_x), f32(win_y)} - (PADDING * 2)},
	)
	append(&spritor.traits, traits.Background{color = rl.BEIGE})
	append(
		&spritor.traits,
		traits.Border{color = rl.BLACK, width = 1, kind = .Outside, direction = .Full},
	)
}

close_spritor :: proc(spritor: ^Spritor) {
	spritor.status = .Closed
	free(&spritor.traits)
}

update_spritor :: proc(spritor: ^Spritor) {
	if is_key_pressed(.PERIOD) {
		current_time := rl.GetTime()

		if current_time - spritor.last_press_time < spritor.limit_press_rate {
			if spritor.status == .Closed {
				open_spritor(spritor)
			} else {
				close_spritor(spritor)
			}
			// Reset to 0 so a third click doesn't trigger another "double" press immediately
			spritor.last_press_time = 0
		} else {
			spritor.last_press_time = current_time
		}
	}
}

PALETTE_COLS :: 4
COLOR_SIZE :: 10
