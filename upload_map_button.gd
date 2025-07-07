extends Button

func _on_pressed():
	open_file_dialog()

func open_file_dialog():
	# Create file dialog
	var file_dialog = FileDialog.new()
	file_dialog.title = "Select Map File"
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.txt", "Text Files")
	file_dialog.add_filter("*.gd", "GDScript Files")
	
	# Set the current directory to the save directory or last upload directory
	var current_dir = get_upload_directory()
	if not current_dir.is_empty():
		file_dialog.current_dir = current_dir
	
	# Add to scene tree temporarily
	get_tree().root.add_child(file_dialog)
	
	# Connect signals
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.canceled.connect(_on_file_dialog_canceled)
	
	# Show dialog
	file_dialog.popup_centered()

func get_upload_directory() -> String:
	# Use the Global function to get the appropriate upload directory
	return Global.get_upload_directory()

func _on_file_selected(path: String):
	# Remember the directory where the file was selected
	Global.last_upload_path = path.get_base_dir()
	
	load_map_from_file(path)
	
	# Update the map name input with the filename (without extension and grid size)
	var filename = path.get_file().get_basename()
	
	# For .gd files, just use the filename as-is since it won't have grid size
	var file_extension = path.get_extension().to_lower()
	var clean_filename = ""
	if file_extension == "gd":
		clean_filename = filename
	else:
		# Remove grid size part from filename (e.g., "GCM (4x4)" -> "GCM")
		clean_filename = extract_base_name_from_filename(filename)
	
	# Find and update the map name input
	var map_name_input = get_tree().get_first_node_in_group("Map Name")
	if not map_name_input:
		# Try to find any LineEdit that might be the map name input
		for node in get_tree().get_nodes_in_group(""):
			if node is LineEdit and node.name == "Map Name":
				map_name_input = node
				break
	
	if map_name_input:
		map_name_input.text = clean_filename
		print_debug("Updated map name to: ", clean_filename)
	else:
		print_debug("Could not find map name input")
	
	# Clean up dialog
	var file_dialog = get_tree().root.get_node_or_null("FileDialog")
	if file_dialog:
		file_dialog.queue_free()

func _on_file_dialog_canceled():
	# Clean up dialog
	var file_dialog = get_tree().root.get_node_or_null("FileDialog")
	if file_dialog:
		file_dialog.queue_free()

func load_map_from_file(file_path: String):
	# Check file extension to determine how to process it
	var file_extension = file_path.get_extension().to_lower()
	
	if file_extension == "gd":
		load_gdscript_file(file_path)
	else:
		load_text_file(file_path)

func load_text_file(file_path: String):
	# Extract filename and check for grid size
	var filename = file_path.get_file().get_basename()
	var grid_size = extract_grid_size_from_filename(filename)
	
	if grid_size == Vector2i.ZERO:
		print_debug("Filename does not contain grid size information. Expected format: filename (widthxheight).txt")
		return
	
	# Resize grid to match the file's grid size
	Global.grid_width = grid_size.x
	Global.grid_height = grid_size.y
	
	# Update the UI input elements to reflect the new grid size
	update_grid_size_inputs()
	
	# Get reference to grid display and rebuild
	var grid_display = get_tree().get_first_node_in_group("Grid Display")
	if not grid_display:
		print_debug("Could not find grid display")
		return
	
	# Rebuild grid with new size
	grid_display.rebuild_grid()
	
	# Read the file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print_debug("Failed to open file: ", file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Parse the JSON content
	var json = JSON.new()
	var parse_result = json.parse(content)
	
	if parse_result != OK:
		print_debug("Failed to parse JSON from file")
		return
	
	var map_data = json.data
	if not map_data is Array:
		print_debug("File does not contain valid map data array")
		return
	
	# Detect and convert data format if needed
	var processed_data = detect_and_convert_data_format(map_data, grid_size)
	
	# Defer applying the map data until after the grid is rebuilt
	call_deferred("_apply_map_data_after_rebuild", grid_display, processed_data)

func load_gdscript_file(file_path: String):
	# Read the GDScript file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print_debug("Failed to open file: ", file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Extract the LAYOUT array from the GDScript
	var map_data = extract_layout_from_gdscript(content)
	if map_data.is_empty():
		print_debug("Could not find LAYOUT array in GDScript file")
		return
	
	# Determine grid size from the data
	var grid_size = Vector2i(map_data[0].size(), map_data.size())
	
	# Resize grid to match the data's grid size
	Global.grid_width = grid_size.x
	Global.grid_height = grid_size.y
	
	# Update the UI input elements to reflect the new grid size
	update_grid_size_inputs()
	
	# Get reference to grid display and rebuild
	var grid_display = get_tree().get_first_node_in_group("Grid Display")
	if not grid_display:
		print_debug("Could not find grid display")
		return
	
	# Rebuild grid with new size
	grid_display.rebuild_grid()
	
	# Defer applying the map data until after the grid is rebuilt
	call_deferred("_apply_map_data_after_rebuild", grid_display, map_data)

func extract_layout_from_gdscript(content: String) -> Array:
	# Find the LAYOUT constant declaration
	var layout_start = content.find("const LAYOUT :=")
	if layout_start == -1:
		layout_start = content.find("const LAYOUT:=")
	
	if layout_start == -1:
		print_debug("Could not find LAYOUT constant in GDScript")
		return []
	
	# Find the opening bracket after LAYOUT :=
	var bracket_start = content.find("[", layout_start)
	if bracket_start == -1:
		print_debug("Could not find opening bracket for LAYOUT array")
		return []
	
	# Find the matching closing bracket
	var bracket_count = 0
	var bracket_end = -1
	
	for i in range(bracket_start, content.length()):
		var current_char = content[i]
		if current_char == "[":
			bracket_count += 1
		elif current_char == "]":
			bracket_count -= 1
			if bracket_count == 0:
				bracket_end = i
				break
	
	if bracket_end == -1:
		print_debug("Could not find closing bracket for LAYOUT array")
		return []
	
	# Extract the array content (excluding the outer brackets)
	var array_content = content.substr(bracket_start + 1, bracket_end - bracket_start - 1)
	
	# Parse the nested array structure
	return parse_nested_array_from_string(array_content)

func parse_nested_array_from_string(array_string: String) -> Array:
	# This is a simplified parser for the nested array structure
	# It handles the basic format: [["Base", "R"], ["G", "F"]]
	
	var result = []
	var lines = array_string.split("\n")
	
	for line in lines:
		line = line.strip_edges()
		if line.is_empty() or not line.begins_with("["):
			continue
		
		# Extract the row array
		var row_start = line.find("[")
		var row_end = line.rfind("]")
		if row_start == -1 or row_end == -1:
			continue
		
		var row_content = line.substr(row_start + 1, row_end - row_start - 1)
		var row = parse_row_from_string(row_content)
		if not row.is_empty():
			result.append(row)
	
	return result

func parse_row_from_string(row_string: String) -> Array:
	# Parse a single row like: "Base", "R", "G", "F"
	var result = []
	var current_item = ""
	var in_quotes = false
	
	for i in range(row_string.length()):
		var current_char = row_string[i]
		
		if current_char == '"':
			in_quotes = !in_quotes
		elif current_char == ',' and not in_quotes:
			# End of item
			result.append(current_item.strip_edges())
			current_item = ""
		else:
			current_item += current_char
	
	# Add the last item
	if not current_item.is_empty():
		result.append(current_item.strip_edges())
	
	return result

func detect_and_convert_data_format(map_data: Array, grid_size: Vector2i) -> Array:
	# Check if data is already in nested format (2D array)
	if map_data.size() > 0 and map_data[0] is Array:
		print_debug("Detected nested array format")
		return map_data
	
	# Check if data is in flat format and convert to nested
	if map_data.size() == grid_size.x * grid_size.y:
		print_debug("Detected flat array format, converting to nested")
		return convert_flat_to_nested(map_data, grid_size)
	
	# If data size doesn't match expected size, show error
	print_debug("Data size doesn't match grid size. Expected: ", grid_size.x * grid_size.y, " Got: ", map_data.size())
	return []

func convert_flat_to_nested(flat_data: Array, grid_size: Vector2i) -> Array:
	var nested_data = []
	
	for y in range(grid_size.y):
		var row = []
		for x in range(grid_size.x):
			var index = y * grid_size.x + x
			if index < flat_data.size():
				row.append(flat_data[index])
			else:
				row.append("")  # Default empty value
		nested_data.append(row)
	
	return nested_data

func _apply_map_data_after_rebuild(grid_display, map_data):
	# Wait a frame to ensure the grid is fully rebuilt
	await get_tree().process_frame
	apply_map_data_to_grid(grid_display, map_data)

func extract_grid_size_from_filename(filename: String) -> Vector2i:
	# Look for pattern: "filename (widthxheight)"
	var regex = RegEx.new()
	regex.compile("\\((\\d+)x(\\d+)\\)")
	var result = regex.search(filename)
	
	if result:
		var width = int(result.get_string(1))
		var height = int(result.get_string(2))
		return Vector2i(width, height)
	
	return Vector2i.ZERO

func extract_base_name_from_filename(filename: String) -> String:
	# Remove grid size part from filename (e.g., "GCM (4x4)" -> "GCM")
	# Look for the pattern and remove everything from the opening parenthesis onwards
	var regex = RegEx.new()
	regex.compile("\\s*\\(.*\\)")
	var result = regex.search(filename)
	
	if result:
		# Return the part before the grid size
		return filename.substr(0, result.get_start())
	else:
		# If no grid size found, return the original filename
		return filename

func apply_map_data_to_grid(grid_display, map_data: Array):
	# Get all cells in the grid
	var cells = []
	for child in grid_display.get_children():
		if child.has_method("get_cell_position"):
			cells.append(child)
	
	# Sort cells by position (top-left to bottom-right, row by row)
	cells.sort_custom(func(a, b): 
		var pos_a = a.get_cell_position()
		var pos_b = b.get_cell_position()
		# First sort by Y (row), then by X (column)
		if pos_a.y < pos_b.y:
			return true
		elif pos_a.y > pos_b.y:
			return false
		else:
			return pos_a.x < pos_b.x
	)
	
	# Apply map data to cells (now handling nested array format)
	for i in range(cells.size()):
		var pos = cells[i].get_cell_position()
		var string_value = ""
		
		# Get value from nested array using position
		if pos.y < map_data.size() and pos.x < map_data[pos.y].size():
			string_value = map_data[pos.y][pos.x]
		
		var cell_value = GlobalClass.get_cell_value_from_string(string_value)
		cells[i].cell_value = cell_value

func update_grid_size_inputs():
	# Find the options node and update the input values
	var options = get_tree().get_first_node_in_group("Options")
	
	if options and options.has_method("update_grid_inputs"):
		options.update_grid_inputs()
		print_debug("Updated grid size inputs in options UI")
	else:
		print_debug("Could not find options UI to update grid inputs") 
	
