package pixore

import co "config"
import "core:c"
import "core:fmt"
import "core:log"
import "core:strings"
import rl "vendor:raylib"
import gl "vendor:raylib/rlgl"

Pixore :: struct {
	width, height:  i32,
	title:          string,
	stop_requested: bool,
	camera:         rl.Camera2D,
	palette:        []rl.Color,
	canvas:         rl.RenderTexture2D,
	resolution:     rl.Vector2,
	color:          int,
}


create :: proc() -> Pixore {
	log.info("Creating pixore game")

	config := co.get_project_config()
	log.info("Using found", config)
	pixore := Pixore {
		width      = config.width,
		height     = config.height,
		title      = config.title,
		resolution = config.resolution,
		palette    = config.palette,
	}

	return pixore
}

save :: proc(p: Pixore) {
	log.info("Saving game")
	co.save_project_config(
		{
			width = p.width,
			height = p.height,
			title = p.title,
			resolution = p.resolution,
			palette = p.palette,
		},
	)
}

start :: proc(
	pixore: ^Pixore,
	state: ^$State,
	draw: proc(state: State),
	update: proc(state: ^State),
) {
	rl.InitWindow(pixore.width, pixore.height, strings.clone_to_cstring(pixore.title))
	rl.SetTargetFPS(60)

	res_x := f32(pixore.resolution.x)
	res_y := f32(pixore.resolution.y)
	assert(res_x > 0, "resolution height is zero")
	assert(res_y > 0, "resolution height is zero")

	pixore.camera.zoom = 1
	pixore.canvas = rl.LoadRenderTexture(i32(res_x), i32(res_y))

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

	fmt.println(margin, final_size)

	context.user_ptr = pixore
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
	p := (^Pixore)(context.user_ptr)
	p.camera.offset = rl.Vector2{x, y}
}

delta_time :: proc() -> f32 {
	return rl.GetFrameTime()
}

stop :: proc() {
	p := (^Pixore)(context.user_ptr)
	p.stop_requested = true
}

// Set a single pixel to a color
set_pixel :: proc(x, y: int, color: int = -1) {
	rl.DrawPixel(c.int(x), c.int(y), get_color(color))
}

// Get the color of a specific pixel
get_pixel :: proc(x, y: int) -> rl.Color {
	p := (^Pixore)(context.user_ptr)
	image := rl.LoadImageFromTexture(p.canvas.texture)
	defer rl.UnloadImage(image)
	color := rl.GetImageColor(image, c.int(x), c.int(y))

	return color
}
