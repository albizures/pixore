package pixore

import co "config"
import "core:c"
import "core:log"
import "core:strings"
import "internals"
import rl "vendor:raylib"

create :: proc() -> internals.Pixore {
	log.info("Creating pixore game")

	config := co.get_project_config()

	pixore := internals.Pixore {
		width      = config.width,
		height     = config.height,
		title      = config.title,
		resolution = config.resolution,
		palette    = config.palette,
		sprite     = config.sprite,
	}

	return pixore
}

save :: proc(p: internals.Pixore) {
	log.info("Saving game")
	co.save_project_config(
		{
			width = p.width,
			height = p.height,
			title = p.title,
			resolution = p.resolution,
			palette = p.palette,
			sprite = p.sprite,
		},
	)
}

@(private)
init :: proc(pixore: ^internals.Pixore) {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(
		c.int(pixore.width),
		c.int(pixore.height),
		strings.clone_to_cstring(pixore.title),
	)
	rl.SetTargetFPS(60)

	res_x := i32(pixore.resolution.x)
	res_y := i32(pixore.resolution.y)
	assert(res_x > 0, "resolution height is zero")
	assert(res_y > 0, "resolution height is zero")

	pixore.camera.zoom = 1
	pixore.sprite_texture = rl.LoadRenderTexture(pixore.sprite.size, pixore.sprite.size)
	rl.SetTextureFilter(pixore.sprite_texture.texture, .POINT)

	pixore.canvas = rl.LoadRenderTexture(res_x, res_y)
	rl.SetTextureFilter(pixore.canvas.texture, .POINT)

	context.user_ptr = pixore

	// render the sprite
	cols := pixore.sprite.size
	rows := pixore.sprite.size
	rl.BeginTextureMode(pixore.sprite_texture)
	for value, index in pixore.sprite.data {
		x := index % int(cols)
		y := index / int(rows)

		rl.DrawPixel(c.int(x), c.int(y), get_color(int(value)))
	}
	rl.EndTextureMode()

	internals.init_spritor(&pixore.spritor)
}

start :: proc(
	pixore: ^internals.Pixore,
	state: ^$State,
	draw: proc(state: State),
	update: proc(state: ^State),
) {
	init(pixore)

	context.user_ptr = pixore

	for !pixore.stop_requested {
		final_size, margin := get_real_size(pixore^)
		if rl.WindowShouldClose() {
			pixore.stop_requested = true
		}
		update(state)
		update_entities(pixore)

		// start drawing canvas
		rl.BeginTextureMode(pixore.canvas)
		rl.BeginMode2D(pixore.camera)

		// /* */rl.DrawFPS(0, 0)
		/* */draw(state^)
		draw_with_traits(pixore.spritor.traits[:])

		// end drawing canvas
		rl.EndMode2D()
		rl.EndTextureMode()

		// draw canvas
		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGRAY)
		rl.DrawTexturePro(
			pixore.canvas.texture,
			{0, 0, f32(pixore.canvas.texture.width), f32(-pixore.canvas.texture.height)}, // Source (flip Y because OpenGL)
			{margin.x, margin.y, final_size, final_size},
			{0, 0},
			0,
			rl.WHITE,
		)
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.UnloadTexture(pixore.canvas.texture)
	rl.CloseWindow()
}

@(private)
get_real_size :: proc(pixore: internals.Pixore) -> (size: f32, margin: rl.Vector2) {
	win_w := rl.GetScreenWidth()
	win_h := rl.GetScreenHeight()
	if win_w < win_h {
		size = f32(win_w)
		extra_space := f32(win_h - win_w)

		margin = {0, extra_space / 2}
	} else {
		size = f32(win_h)
		extra_space := f32(win_w - win_h)

		margin = {extra_space / 2, 0}
	}

	return size, margin
}

stop :: proc() {
	p := (^internals.Pixore)(context.user_ptr)
	p.stop_requested = true
}
