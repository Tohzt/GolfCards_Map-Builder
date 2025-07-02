class_name GlobalClass extends Node

@export var cell_size: int = 64
@export var grid_width: int = 10
@export var grid_height: int = 10
@export var custom_save_path: String = ""  # Empty means use downloads folder

# Cell types configuration - each dictionary contains name, value, and color
# You can modify this array in the editor to add/remove cell types or change colors
# Each dictionary should have: "name" (String), "value" (int), "color" (Color)
@export var cell_types: Array[Dictionary] = [
	{"name": "Empty", "value": -1, "color": Color.BLACK},
	{"name": "Base", "value": 0, "color": Color.BLUE},
	{"name": "G", "value": 1, "color": Color.LIGHT_GREEN},
	{"name": "R", "value": 2, "color": Color.RED},
	{"name": "F", "value": 3, "color": Color.FOREST_GREEN},
	{"name": "S", "value": 4, "color": Color.SANDY_BROWN},
	{"name": "Tee", "value": 5, "color": Color.WHITE}
]
 

# Get the display name for a cell value
static func get_cell_string(value: int) -> String:
	for cell_type in Global.cell_types:
		if cell_type.value == value:
			return cell_type.name
	return str(value)  # Fallback for unknown values

# Get the cell value from a display name
static func get_cell_value_from_string(string_value: String) -> int:
	for cell_type in Global.cell_types:
		if cell_type.name == string_value:
			return cell_type.value
	return -1  # Return EMPTY as fallback for unknown strings

# Get the color for a cell value
static func get_cell_color(value: int) -> Color:
	for cell_type in Global.cell_types:
		if cell_type.value == value:
			return cell_type.color
	return Color.BLACK  # Return black as fallback

func get_save_directory() -> String:
	if custom_save_path.is_empty():
		return OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	else:
		return custom_save_path
