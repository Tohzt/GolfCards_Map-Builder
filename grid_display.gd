extends Node2D

var is_painting: bool = false
var last_painted_cell: Node2D = null

func _ready() -> void:
	build_grid()

func build_grid() -> void:
	# Calculate grid dimensions
	var grid_width_pixels = Global.grid_width * Global.cell_size
	var grid_height_pixels = Global.grid_height * Global.cell_size
	
	# Center the grid by offsetting this node
	position = Vector2(-grid_width_pixels / 2, -grid_height_pixels / 2)
	
	# Load the cell scene
	var cell_scene = preload("res://cell.tscn")
	
	# Create grid of cells
	for x in Global.grid_width:
		for y in Global.grid_height:
			# Create a new cell instance
			var cell = cell_scene.instantiate()
			
			# Position the cell based on grid coordinates and cell size
			cell.position = Vector2(x * Global.cell_size, y * Global.cell_size)
			
			# Add the cell as a child of this node
			add_child(cell)

func rebuild_grid() -> void:
	# Store existing cell values before clearing
	var old_cell_values = {}
	for child in get_children():
		if child.has_method("get_cell_position"):
			var pos = child.get_cell_position()
			old_cell_values[pos] = child.cell_value
	
	# Clear existing grid
	for child in get_children():
		child.queue_free()
	
	# Rebuild with new dimensions
	build_grid()
	
	# Restore cell values where possible
	for child in get_children():
		if child.has_method("get_cell_position"):
			var pos = child.get_cell_position()
			if old_cell_values.has(pos):
				child.cell_value = old_cell_values[pos]

func _input(event: InputEvent) -> void:
	# Handle painting with mouse drag
	if event.is_action_pressed("mouse left"):
		is_painting = true
		last_painted_cell = null
	
	elif event.is_action_released("mouse left"):
		is_painting = false
		last_painted_cell = null
	
	elif event.is_action_pressed("mouse right"):
		is_painting = true
		last_painted_cell = null
	
	elif event.is_action_released("mouse right"):
		is_painting = false
		last_painted_cell = null
	
	# Handle painting while dragging
	if is_painting:
		var mouse_pos = get_global_mouse_position()
		var cell = get_cell_at_position(mouse_pos)
		
		if cell and cell != last_painted_cell:
			last_painted_cell = cell
			
			# Paint with selected cell type for left click, empty for right click
			if Input.is_action_pressed("mouse left"):
				var cell_selection = get_tree().get_first_node_in_group("Cell Selection")
				if cell_selection and cell_selection.has_method("get_selected_cell_type"):
					cell.cell_value = cell_selection.get_selected_cell_type()
			elif Input.is_action_pressed("mouse right"):
				cell.cell_value = Global.cell_types[0].value  # EMPTY value

func get_cell_at_position(world_pos: Vector2) -> Node2D:
	# Convert world position to local position
	var local_pos = to_local(world_pos)
	
	# Convert to grid coordinates with more precise calculation
	var grid_x = int(round(local_pos.x / Global.cell_size))
	var grid_y = int(round(local_pos.y / Global.cell_size))
	
	# Check if position is within grid bounds
	if grid_x >= 0 and grid_x < Global.grid_width and grid_y >= 0 and grid_y < Global.grid_height:
		# Calculate the exact cell bounds to ensure we're clearly within the cell
		var cell_center_x = (grid_x + 0.5) * Global.cell_size
		var cell_center_y = (grid_y + 0.5) * Global.cell_size
		var distance_from_center = Vector2(local_pos.x - cell_center_x, local_pos.y - cell_center_y).length()
		
		# Only paint if we're within 80% of the cell radius (more precise than edge detection)
		var max_distance = Global.cell_size * 0.4  # 80% of half the cell size
		if distance_from_center <= max_distance:
			# Find the cell at this grid position
			for child in get_children():
				if child.has_method("get_cell_position"):
					var cell_pos = child.get_cell_position()
					if cell_pos == Vector2i(grid_x, grid_y):
						return child
	
	return null
