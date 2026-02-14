package api

import "../base"
import rl "vendor:raylib"
import gl "vendor:raylib/rlgl"

push :: proc() {
	gl.PushMatrix()
}

pop :: proc() {
	gl.PopMatrix()
}

translate :: proc(x: f32 = 0, y: f32 = 0) {
	gl.Translatef(x, y, 0)
}

set_offset :: proc(x, y: f32) {
	p := (^base.Pixore)(context.user_ptr)
	p.camera.offset = rl.Vector2{x, y}
}

delta_time :: proc() -> f32 {
	return rl.GetFrameTime()
}
