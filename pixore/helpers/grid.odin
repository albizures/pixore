package helpers


get_grid_cell :: proc(index: int, size: int) -> (x: int, y: int) {
	x = index % size
	y = index / size

	return
}
