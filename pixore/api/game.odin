package api

import "../base"
import co "../config"
import "core:c"
import "core:log"
import "core:strings"
import rl "vendor:raylib"


create :: proc() -> base.Pixore {
	log.info("Creating pixore game")

	config := co.get_project_config()

	pixore := base.Pixore {
		width      = config.width,
		height     = config.height,
		title      = config.title,
		resolution = config.resolution,
		palette    = config.palette,
		sprite     = config.sprite,
	}

	return pixore
}

save :: proc(p: base.Pixore) {
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

start :: proc(
	pixore: ^base.Pixore,
	state: ^$State,
	draw: proc(state: State),
	update: proc(state: ^State),
) {
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
	pixore.canvas = rl.LoadRenderTexture(res_x, res_y)

	final_size: f32
	margin: rl.Vector2

	if pixore.width < pixore.height {
		final_size = f32(pixore.width)
		extra_space := f32(pixore.height - pixore.width)

		margin = {0, extra_space / 2}
	} else {
		final_size = f32(pixore.height)
		extra_space := f32(pixore.width - pixore.height)

		margin = {extra_space / 2, 0}
	}

	context.user_ptr = pixore
	cols := pixore.sprite.size
	rows := pixore.sprite.size
	rl.BeginTextureMode(pixore.sprite_texture)
	for value, index in pixore.sprite.data {
		x := index % int(cols)
		y := index / int(rows)

		rl.DrawPixel(c.int(x), c.int(y), get_color(int(value)))
	}

	rl.EndTextureMode()


	for !pixore.stop_requested {
		if rl.WindowShouldClose() {
			pixore.stop_requested = true
		}
		update(state)

		// start drawing canvas
		rl.BeginTextureMode(pixore.canvas)
		rl.BeginMode2D(pixore.camera)


		/* */rl.DrawFPS(0, 0)
		/* */draw(state^)

		// end drawing canvas
		rl.EndMode2D()
		rl.EndTextureMode()

		// draw canvas
		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGRAY)
		rl.DrawTexturePro(
			pixore.canvas.texture,
			{0, 0, f32(pixore.canvas.texture.width), f32(-pixore.canvas.texture.height)}, // Source (flip Y because OpenGL)
			{margin.x, margin.y, f32(final_size), f32(final_size)}, // TODO make it expand to the available space
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

stop :: proc() {
	p := (^base.Pixore)(context.user_ptr)
	p.stop_requested = true
}
