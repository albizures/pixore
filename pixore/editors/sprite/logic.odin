package sprite_editor

import "../../api"
import se "../../base/sprite_editor"
import rl "vendor:raylib"

PADDING :: 10

init :: proc(state: ^se.State) {
	state.limit_press_rate = 0.25
}

update :: proc(state: ^se.State) {
	if api.is_key_pressed(.PERIOD) {
		current_time := rl.GetTime()

		if current_time - state.last_press_time < state.limit_press_rate {
			state.status = .Open if state.status == .Closed else .Closed
			// Reset to 0 so a third click doesn't trigger another "double" press immediately
			state.last_press_time = 0
		} else {
			state.last_press_time = current_time
		}
	}
}

draw :: proc(state: se.State) {
	if state.status == .Open {
		win_x, win_y := api.win_size()
		api.rect(PADDING, PADDING, win_x - PADDING * 2, win_y - PADDING * 2, 2)
	}
}
