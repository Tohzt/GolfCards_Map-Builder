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
	
	# Add to scene tree temporarily
	get_tree().root.add_child(file_dialog)
	
	# Connect signals
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.canceled.connect(_on_file_dialog_canceled)
	
	# Show dialog
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	print("Selected file: ", path)
	load_map_from_file(path)
	
	# Update the map name input with the filename (without extension and grid size)
	var filename = path.get_file().get_basename()
	# Remove grid size part from filename (e.g., "GCM (4x4)" -> "GCM")
	var clean_filename = extract_base_name_from_filename(filename)
	print("Original filename: ", filename, " -> Clean filename: ", clean_filename)
	
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
		print("Updated map name to: ", clean_filename)
	else:
		print("Could not find map name input")
	
	# Clean up dialog
	var file_dialog = get_tree().root.get_node_or_null("FileDialog")
	if file_dialog:
		file_dialog.queue_free()

func _on_file_dialog_canceled():
	print("File selection canceled")
	
	# Clean up dialog
	var file_dialog = get_tree().root.get_node_or_null("FileDialog")
	if file_dialog:
		file_dialog.queue_free()

func load_map_from_file(file_path: String):
	# Extract filename and check for grid size
	var filename = file_path.get_file().get_basename()
	var grid_size = extract_grid_size_from_filename(filename)
	
	if grid_size == Vector2i.ZERO:
		print("Filename does not contain grid size information. Expected format: filename (widthxheight).txt")
		return
	
	print("Loading map with grid size: ", grid_size)
	print("Current Global grid size: ", Vector2i(Global.grid_width, Global.grid_height))
	
	# Resize grid to match the file's grid size
	Global.grid_width = grid_size.x
	Global.grid_height = grid_size.y
	print("Updated Global grid size to: ", Vector2i(Global.grid_width, Global.grid_height))
	
	# Update the UI input elements to reflect the new grid size
	update_grid_size_inputs()
	
	# Get reference to grid display and rebuild
	var grid_display = get_tree().get_first_node_in_group("Grid Display")
	if not grid_display:
		print("Could not find grid display")
		return
	
	# Rebuild grid with new size
	grid_display.rebuild_grid()
	
	# Read the file
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open file: ", file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Parse the JSON content
	var json = JSON.new()
	var parse_result = json.parse(content)
	
	if parse_result != OK:
		print("Failed to parse JSON from file")
		return
	
	var map_data = json.data
	if not map_data is Array:
		print("File does not contain valid map data array")
		return
	
	# Defer applying the map data until after the grid is rebuilt
	call_deferred("_apply_map_data_after_rebuild", grid_display, map_data)

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
	
	# Debug: Print the sorted cell positions to verify order
	print("Sorted cell positions:")
	for i in range(cells.size()):
		var pos = cells[i].get_cell_position()
		var world_pos = cells[i].global_position
		var local_pos = cells[i].position
		print("Cell ", i, ": grid_pos=", pos, " local_pos=", local_pos, " world_pos=", world_pos, " -> ", map_data[i] if i < map_data.size() else "N/A")
	
	# Apply map data to cells
	for i in range(min(map_data.size(), cells.size())):
		var string_value = map_data[i]
		var cell_value = Global.get_cell_value_from_string(string_value)
		cells[i].cell_value = cell_value
	
	print("Map loaded successfully! Applied ", map_data.size(), " values to ", cells.size(), " cells")

func update_grid_size_inputs():
	# Find the options node and update the input values
	var options = get_tree().get_first_node_in_group("Options")
	
	if options and options.has_method("update_grid_inputs"):
		options.update_grid_inputs()
		print("Updated grid size inputs in options UI")
	else:
		print("Could not find options UI to update grid inputs") 
	
