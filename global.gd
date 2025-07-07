class_name GlobalClass extends Node

@export var cell_size: int = 64
@export var grid_width: int = 10
@export var grid_height: int = 10
@export var custom_save_path: String = ""  # Empty means use downloads folder
@export var last_upload_path: String = ""  # Remember last upload directory

# Cell types configuration - each dictionary contains name, value, and color
# You can modify this array in the editor to add/remove cell types or change colors
# Each dictionary should have: "name" (String), "value" (int), "color" (Color)
@onready var BRUSH_TYPES: PackedScene = preload("res://Brush Stuff/brush_selection_cell.tscn")

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
		return get_windows_downloads_folder()
	else:
		return custom_save_path

func get_upload_directory() -> String:
	if last_upload_path.is_empty():
		return get_save_directory()
	else:
		return last_upload_path

func get_windows_downloads_folder() -> String:
	# Try multiple methods to find the Windows Downloads folder
	
	# Method 1: Use Godot's system directory function
	var downloads_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if not downloads_dir.is_empty() and DirAccess.dir_exists_absolute(downloads_dir):
		return downloads_dir
	
	# Method 2: Try common Windows Downloads paths
	var possible_paths = [
		OS.get_environment("USERPROFILE") + "/Downloads",
		OS.get_environment("USERPROFILE") + "\\Downloads",
		"C:/Users/" + OS.get_environment("USERNAME") + "/Downloads",
		"C:\\Users\\" + OS.get_environment("USERNAME") + "\\Downloads"
	]
	
	for path in possible_paths:
		if DirAccess.dir_exists_absolute(path):
			return path
	
	# Method 3: Fallback to user's home directory
	var home_dir = OS.get_environment("USERPROFILE")
	if not home_dir.is_empty() and DirAccess.dir_exists_absolute(home_dir):
		return home_dir
	
	# Method 4: Final fallback to current working directory
	return "."
