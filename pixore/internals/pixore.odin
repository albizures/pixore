package pixore_internals

import "../common"
import co "../config"
import "../events"
import "../helpers"
import "../traits"
import "core:c"
import "core:log"
import "core:mem"
import "core:strings"
import rl "vendor:raylib"

Pixore :: common.Pixore
RESOURCES_ARENA_SIZE := 20 * mem.Kilobyte
SYSTEMS_ARENA_SIZE := 18 * mem.Kilobyte

init :: proc(pixore: ^Pixore) {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(
		c.int(pixore.config.window_size.x),
		c.int(pixore.config.window_size.y),
		strings.clone_to_cstring(pixore.config.title),
	)
	rl.SetTargetFPS(60)

	context.user_ptr = pixore

	init_resources(pixore)
	init_rendering(pixore)
	init_systems(pixore)
}

init_resources :: proc(pixore: ^Pixore) {
	config := &pixore.config
	res := &pixore.resources

	helpers.init_arena(res, RESOURCES_ARENA_SIZE)
	defer helpers.print_remaining(res, "resources")

	size := config.sprite.size

	res.palette = make([dynamic]rl.Color, len(config.palette), res.allocator)
	res.sprite.data = make([dynamic]u8, len(config.sprite.data), res.allocator)
	res.sprite.size = size


	copy(res.palette[:], pixore.config.palette[:])
	copy(res.sprite.data[:], pixore.config.sprite.data[:])
}

init_rendering :: proc(pixore: ^Pixore) {
	rendering := &pixore.rendering
	sprite := &pixore.resources.sprite

	rendering.camera.zoom = 1
	rendering.sprite_texture = rl.LoadRenderTexture(c.int(sprite.size), c.int(sprite.size))
	rl.SetTextureFilter(rendering.sprite_texture.texture, .POINT)

	res_x := i32(pixore.config.screen_size.x)
	res_y := i32(pixore.config.screen_size.y)
	assert(res_x > 0, "resolution height is zero")
	assert(res_y > 0, "resolution height is zero")

	rendering.canvas = rl.LoadRenderTexture(res_x, res_y)
	rl.SetTextureFilter(rendering.canvas.texture, .POINT)

	// render the sprite
	cols := int(pixore.resources.sprite.size)
	rl.BeginTextureMode(rendering.sprite_texture)
	for value, index in pixore.resources.sprite.data {
		x, y := helpers.get_grid_cell(index, cols)

		rl.DrawPixelV({f32(x), f32(y)}, get_color(int(value)))
	}
	rl.EndTextureMode()
}

init_systems :: proc(pixore: ^Pixore) {
	systems := &pixore.systems

	helpers.init_arena(systems, SYSTEMS_ARENA_SIZE)
	defer helpers.print_remaining(systems, "systems")

	systems.world = traits.create(systems.allocator, auto_load = true)
	systems.root_entity = traits.create(&systems.world)

	traits.add(&systems.world, Children, traits.Store_Config {
		on_before_remove = proc(world: ^traits.World, entity: traits.Entity) {
			if children, ok := traits.get(world, entity, Children); ok {
				free(&children.entities, children.allocator)
			}
		},
	})

	traits.add(
		&systems.world,
		systems.root_entity,
		Pos{rect = {0, 0, pixore.config.screen_size.x, pixore.config.screen_size.y}},
	)

	systems.dispatcher = events.create(context.allocator)

	events.on(&systems.dispatcher, Color_Change, update_selected_color)
	events.on(&systems.dispatcher, Color_Change, sync_selected_color)
}


create :: proc() -> common.Pixore {
	log.info("Creating pixore game")

	pixore := common.Pixore {
		config = co.get_project_config(),
		editors = {spritor = create_spritor()},
	}

	return pixore
}


update_selected_color :: proc(event: Color_Change) {
	p := event.pixore

	p.state.selected_color = event.index
}

start :: proc(
	pixore: ^Pixore,
	state: ^$State,
	draw: proc(state: State),
	update: proc(state: ^State),
) {
	init(pixore)

	context.user_ptr = pixore

	for !pixore.state.stop_requested {
		final_size, margin := get_real_size(pixore^)
		if rl.WindowShouldClose() {
			pixore.state.stop_requested = true
		}
		update(state)
		update_entities(pixore)

		// start drawing canvas
		rl.BeginTextureMode(pixore.rendering.canvas)
		rl.BeginMode2D(pixore.rendering.camera)

		// /* */rl.DrawFPS(0, 0)
		/* */draw(state^)
		draw_spritor(pixore)

		// end drawing canvas
		rl.EndMode2D()
		rl.EndTextureMode()

		// draw canvas
		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGRAY)
		rl.DrawTexturePro(
			pixore.rendering.canvas.texture,
			{
				0,
				0,
				f32(pixore.rendering.canvas.texture.width),
				f32(-pixore.rendering.canvas.texture.height),
			}, // Source (flip Y because OpenGL)
			{margin.x, margin.y, final_size, final_size},
			{0, 0},
			0,
			rl.WHITE,
		)
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.UnloadTexture(pixore.rendering.canvas.texture)
	rl.CloseWindow()
}

stop :: proc() {
	p := (^Pixore)(context.user_ptr)
	p.state.stop_requested = true
}

update_entities :: proc(pixore: ^Pixore) {
	update_spritor(pixore)
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
