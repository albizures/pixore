package pixore

import "core:log"
import rl "vendor:raylib"

spr :: proc(x, y, width, height, dest_x, dest_y: int) {
	p := (^Pixore)(context.user_ptr)

	width := f32(width)
	height := f32(height)
	x := f32(x)
	y := -height - f32(y) // flipping because of OpenGL
	dest_x := f32(dest_x)
	dest_y := f32(dest_y)

	rl.DrawTexturePro(
		p.sprite_texture.texture,
		{x, y, width, -height},
		{dest_x, dest_y, width, height},
		{0, 0},
		0,
		rl.WHITE,
	)
}
