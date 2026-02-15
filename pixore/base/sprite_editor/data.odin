package sprite_editor_data

Status :: enum {
	Closed,
	Open,
}

State :: struct {
	status:           Status,
	last_press_time:  f64,
	// the time between two interactions to be considered a double click
	limit_press_rate: f64,
}
