package pixore_internals

import "../helpers"
import "../traits"
import "core:c"
import "core:strings"
import rl "vendor:raylib"

Sprite :: struct {
	size: i32,
	// this array should be a square of: <size> x <size>
	data: [dynamic]uint,
}

Config :: struct #all_or_none {
	width, height: uint,
	title:         string,
	resolution:    rl.Vector2,
	palette:       []rl.Color,
	sprite:        Sprite,
}

Pixore :: struct {
	width, height:  uint,
	title:          string,
	stop_requested: bool,
	camera:         rl.Camera2D,
	palette:        []rl.Color,
	selected_color: int,
	canvas:         rl.RenderTexture2D,
	resolution:     rl.Vector2,
	sprite:         Sprite,
	sprite_texture: rl.RenderTexture2D,
	spritor:        Spritor,
	world:          traits.World,
	root_entity:    traits.Entity,
}


init :: proc(pixore: ^Pixore) {
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
	cols := int(pixore.sprite.size)
	rl.BeginTextureMode(pixore.sprite_texture)
	for value, index in pixore.sprite.data {
		x, y := helpers.get_grid_cell(index, cols)

		rl.DrawPixelV({f32(x), f32(y)}, get_color(int(value)))
	}
	rl.EndTextureMode()


	pixore.world = traits.make_world(context.allocator, auto_load = true)
	pixore.root_entity = traits.make_entity(&pixore.world)
	traits.add(&pixore.world, Children, traits.Store_Config {
		on_before_remove = proc(world: ^traits.World, entity: traits.Entity) {
			if children, ok := traits.get(world^, entity, Children); ok {
				free(&children.entities, children.allocator)
			}
		},
	})


	traits.add(
		&pixore.world,
		pixore.root_entity,
		Pos{rect = {0, 0, pixore.resolution.x, pixore.resolution.y}},
	)
}

start :: proc(
	pixore: ^Pixore,
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
		draw_spritor(pixore^)

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

stop :: proc() {
	p := (^Pixore)(context.user_ptr)
	p.stop_requested = true
}

update_entities :: proc(pixore: ^Pixore) {
	update_spritor(pixore)
}


PALETTE_CODES := [?]rune {
	'o',
	'1',
	'2',
	'3',
	'4',
	'5',
	'6',
	'7',
	'8',
	'9',
	'0',
	'a',
	'b',
	'c',
	'd',
	'e',
	'f',
	'g',
	'h',
	'i',
	'j',
	'k',
}

palette_codes_to_map :: proc(allocator := context.allocator) -> map[rune]uint {
	codes := make(map[rune]uint)

	for code, index in PALETTE_CODES {
		codes[code] = uint(index)
	}

	return codes
}


get_real_size :: proc(pixore: Pixore) -> (size: f32, margin: rl.Vector2) {
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
