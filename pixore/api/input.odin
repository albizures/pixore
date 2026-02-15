package api

import rl "vendor:raylib"

is_key_pressed :: proc(key: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressed(key)
}

is_key_pressed_again :: proc(key: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressedRepeat(key)
}
