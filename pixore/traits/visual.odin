package traits

import rl "vendor:raylib"

Direction :: enum {
	Full,
	Top,
	Bottom,
	Left,
	Right,
	Vertical,
	Horizontal,

	// flags
	Is_Mouse_Interactive,
}

Is_Mouse_Interactive :: struct {}

Padding :: struct {
	direction: Direction,
	value:     int,
}

Margin :: struct {
	direction: Direction,
	value:     int,
}

Border_Kind :: enum {
	Outside,
	Inside,
}

Border :: struct {
	direction: Direction,
	width:     int,
	color:     rl.Color,
	kind:      Border_Kind,
}

Background :: struct {
	color: rl.Color,
}
