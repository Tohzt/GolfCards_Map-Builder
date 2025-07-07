extends Button

func _on_pressed():
	save_grid_to_file()

func save_grid_to_file():
	# Get reference to the grid display
	var grid_display = get_tree().get_first_node_in_group("Grid Display")
	if not grid_display:
		print_debug("Could not find grid display")
		return
	
	# Get reference to the map name input
	var map_name_input = get_tree().get_first_node_in_group("Map Name")
	if not map_name_input:
		print_debug("Could not find map name input")
		return
	
	# Convert grid to nested array structure (rows)
	var grid_rows = []
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
	
	# Initialize rows array
	for y in range(Global.grid_height):
		grid_rows.append([])
		for x in range(Global.grid_width):
			grid_rows[y].append("")  # Initialize with empty string
	
	# Fill the rows with cell values
	for i in range(cells.size()):
		var pos = cells[i].get_cell_position()
		var cell_value = cells[i].cell_value
		var string_value = GlobalClass.get_cell_string(cell_value)
		grid_rows[pos.y][pos.x] = string_value
	
	# Convert to JSON format (nested array structure)
	var json_string = JSON.stringify(grid_rows)
	
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
	
	# Check if file already exists
	if FileAccess.file_exists(full_path):
		# Show confirmation dialog
		show_overwrite_confirmation_dialog(full_path, json_string)
	else:
		# Save the file directly
		save_file_to_path(full_path, json_string)

func show_overwrite_confirmation_dialog(file_path: String, json_string: String):
	# Create confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.title = "File Already Exists"
	dialog.dialog_text = "A file with this name already exists:\n" + file_path.get_file() + "\n\nDo you want to overwrite it?"
	dialog.add_button("Cancel", false, "cancel")
	dialog.add_button("Overwrite", true, "overwrite")
	
	# Add to scene tree temporarily
	get_tree().root.add_child(dialog)
	
	# Connect signals
	dialog.confirmed.connect(_on_overwrite_confirmed.bind(file_path, json_string))
	dialog.custom_action.connect(_on_dialog_action.bind(file_path, json_string))
	dialog.canceled.connect(_on_dialog_canceled)
	
	# Show dialog
	dialog.popup_centered()

func _on_overwrite_confirmed(file_path: String, json_string: String):
	# User clicked "Overwrite" button
	save_file_to_path(file_path, json_string)
	cleanup_dialog()

func _on_dialog_action(action: String, file_path: String, json_string: String):
	if action == "overwrite":
		save_file_to_path(file_path, json_string)
	elif action == "cancel":
		print_debug("Save cancelled by user")
	cleanup_dialog()

func _on_dialog_canceled():
	print_debug("Save cancelled by user")
	cleanup_dialog()

func cleanup_dialog():
	# Clean up dialog
	var dialog = get_tree().root.get_node_or_null("AcceptDialog")
	if dialog:
		dialog.queue_free()

func save_file_to_path(file_path: String, json_string: String):
	# Save the file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print_debug("Map saved to: ", file_path)
	else:
		print_debug("Failed to save file to: ", file_path)
