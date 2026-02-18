package pixore

import "internals"


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
