class_name GlobalClass extends Node

@export var cell_size: int = 64
@export var grid_width: int = 20
@export var grid_height: int = 20

enum CellType {
	EMPTY = -1,
	BASE = 0,
	G = 1,
	R = 2,
	F = 3,
	S = 4,
	TEE = 5
}

static func get_cell_string(value: int) -> String:
	match value:
		CellType.EMPTY: return ""
		CellType.BASE: return "Base"
		CellType.G: return "G"
		CellType.R: return "R"
		CellType.F: return "F"
		CellType.S: return "S"
		CellType.TEE: return "Tee"
		_: return str(value)  # Fallback for unknown values
