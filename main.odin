package game

import "core:log"
import p "pixore"
import rl "vendor:raylib"

Game_State :: struct {
	counter:         int,
	shake_intensity: f32,
	shake_duration:  f32,
}

main :: proc() {
	logger := log.create_console_logger()
	context.logger = logger
	defer log.destroy_console_logger(logger)

	pixore := p.create()
	defer p.save(pixore)

	state := Game_State{}

	p.start(&pixore, &state, update = update, draw = draw)
}

update :: proc(state: ^Game_State) {
	// Update game state
	state.counter += 1

	shake(&state.shake_duration, &state.shake_intensity)

	if (rl.IsKeyPressed(.SPACE)) {
		state.shake_intensity = 30.0 // pixels
		state.shake_duration = 0.5 // seconds
	}
}


draw :: proc(state: Game_State) {
	p.push()
	defer p.pop()

	p.cls(1)
	p.circle(20, 20, 6, 2)
	p.rect_fill(50, 50, 50, 50, 6)

	p.translate(50, 50)
	p.rect_fill(50, 50, 50, 50, 4)
}

shake :: proc(shake_duration: ^f32, shake_intensity: ^f32) {
	if shake_duration^ > 0 {
		shake_duration^ -= p.delta_time()

		// Calculate random offset
		// We use intensity to bound the randomness
		offset_x := f32(rl.GetRandomValue(-100, 100)) / 100.0 * shake_intensity^
		offset_y := f32(rl.GetRandomValue(-100, 100)) / 100.0 * shake_intensity^

		p.set_offset(offset_x, offset_y)
	} else {
		p.set_offset(0, 0)
		shake_intensity^ = 0
		shake_duration^ = 0
	}
}
