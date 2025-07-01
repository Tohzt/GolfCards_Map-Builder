extends Button

func _on_pressed():
	save_grid_to_file()

func save_grid_to_file():
	# Get reference to the grid display
	var grid_display = get_tree().get_first_node_in_group("Grid Display")
	if not grid_display:
		print("Could not find grid display")
		return
	
	# Get reference to the map name input
	var map_name_input = get_tree().get_first_node_in_group("Map Name")
	if not map_name_input:
		print("Could not find map name input")
		return
	
	# Convert grid to string array (sorted by position)
	var grid_strings = []
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
	print("Saving - Grid dimensions: ", Vector2i(Global.grid_width, Global.grid_height))
	print("Saving - Sorted cell positions:")
	for i in range(cells.size()):
		var pos = cells[i].get_cell_position()
		var cell_value = cells[i].cell_value
		var string_value = Global.get_cell_string(cell_value)
		print("Cell ", i, ": ", pos, " -> ", string_value)
		grid_strings.append(string_value)
	
	# Convert to JSON format (similar to your example)
	var json_string = JSON.stringify(grid_strings)
	
	# Get save directory from Global
	var save_directory = Global.get_save_directory()
	var filename = map_name_input.text
	if filename.is_empty():
		filename = "map_data"
	
	# Check if filename already has grid size and update it
	var regex = RegEx.new()
	regex.compile("\\s*\\(\\d+x\\d+\\)\\s*$")
	if regex.search(filename):
		# Remove existing grid size and add current one
		filename = regex.sub(filename, "", true)
	
	# Append current grid size to filename
	filename += " (" + str(Global.grid_width) + "x" + str(Global.grid_height) + ")"
	filename += ".txt"
	var full_path = save_directory.path_join(filename)
	
	# Save the file
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Map saved to: ", full_path)
	else:
		print("Failed to save file to: ", full_path)
