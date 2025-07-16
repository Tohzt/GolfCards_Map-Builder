extends Button

func _on_pressed():
	copy_grid_to_clipboard()

func copy_grid_to_clipboard():
	# Get reference to the grid display
	var grid_display = get_tree().get_first_node_in_group("Grid Display")
	if not grid_display:
		print_debug("Could not find grid display")
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
	
	# Convert to GDScript array format
	var gdscript_array = convert_to_gdscript_format(grid_rows)
	
	# Copy to clipboard
	DisplayServer.clipboard_set(gdscript_array)
	print_debug("Map data copied to clipboard!")

func convert_to_gdscript_format(grid_rows: Array) -> String:
	# Convert the nested array to GDScript format
	var result = "const LAYOUT := [\n"
	
	for y in range(grid_rows.size()):
		var row = grid_rows[y]
		result += "\t["
		
		for x in range(row.size()):
			var cell_value = row[x]
			result += "\"" + cell_value + "\""
			
			# Add comma if not the last item in the row
			if x < row.size() - 1:
				result += ", "
		
		result += "]"
		
		# Add comma if not the last row
		if y < grid_rows.size() - 1:
			result += ","
		
		result += "\n"
	
	result += "]"
	return result
