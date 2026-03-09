package helpers


get_grid_cell :: proc(index, size: $Num) -> (x: Num, y: Num) {
	x = index % size
	y = index / size

	return
}


get_grid_index :: proc(x, y, size: $Num) -> Num {
	return x + y * size
}
