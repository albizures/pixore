package pixore

import "api"


// colors
get_color :: api.get_color
set_pixel :: api.set_pixel
get_pixel :: api.get_pixel

// graphics
push :: api.push
pop :: api.pop
translate :: api.translate
set_offset :: api.set_offset
delta_time :: api.delta_time

//draw
circle :: api.circle
circle_fill :: api.circle_fill
rect :: api.rect
rect_fill :: api.rect_fill
ellipse :: api.ellipse
ellipse_fill :: api.ellipse_fill
cls :: api.cls

// sprites
spr :: api.spr
