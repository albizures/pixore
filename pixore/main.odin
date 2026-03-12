package pixore

import co "config"
import "core:log"
import "internals"


create :: proc() -> internals.Pixore {
	log.info("Creating pixore game")

	config := co.get_project_config()

	pixore := internals.Pixore {
		width          = config.width,
		height         = config.height,
		title          = config.title,
		resolution     = config.resolution,
		palette        = config.palette,
		sprite         = config.sprite,
		spritor        = internals.new_spritor(),
		selected_color = 0,
	}

	return pixore
}


// core
start :: internals.start
stop :: internals.stop
save :: co.save

// colors
get_color :: internals.get_color
set_pixel :: internals.set_pixel
get_pixel :: internals.get_pixel

// graphics
push :: internals.push
pop :: internals.pop
translate :: internals.translate
set_offset :: internals.set_offset
delta_time :: internals.delta_time

//draw
circle :: internals.circle
circle_fill :: internals.circle_fill
rect :: internals.rect
rect_fill :: internals.rect_fill
ellipse :: internals.ellipse
ellipse_fill :: internals.ellipse_fill
cls :: internals.cls

// sprites
spr :: internals.spr
