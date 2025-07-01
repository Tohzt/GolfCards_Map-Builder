extends Node2D

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
