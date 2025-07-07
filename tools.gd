extends MarginContainer

# References to UI elements
@onready var toggle_input = $"NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/Toggle Input"
@onready var margin_container = self  # This script is attached to the MarginContainer
@onready var vbox_container = $"NinePatchRect/MarginContainer/VBoxContainer"
@onready var draw_rect_button = $"NinePatchRect/MarginContainer/VBoxContainer/Draw Rect"
@onready var draw_brush_button = $"NinePatchRect/MarginContainer/VBoxContainer/Draw Brush"

var is_collapsed: bool = false

# Tool mode management
enum ToolMode { BRUSH, RECT }
var current_tool_mode: ToolMode = ToolMode.BRUSH

# For rectangle drawing
var rect_start: Vector2i = Vector2i(-1, -1)
var rect_end: Vector2i = Vector2i(-1, -1)
var is_rect_drawing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set initial highlight
	draw_brush_button.modulate = Color(0.7, 1, 0.7)
	draw_rect_button.modulate = Color(1, 1, 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
	if current_tool_mode == ToolMode.RECT:
		var grid_display = get_tree().get_first_node_in_group("Grid Display")
		if grid_display:
			# Determine current preview rectangle
			var preview_start = rect_start
			var preview_end = rect_end
			if is_rect_drawing:
				# Get current mouse cell
				var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
				var curr_pos = _get_nearest_cell_grid_pos(mouse_pos)
				if curr_pos != Vector2i(-1, -1):
					preview_end = curr_pos
			# Calculate bounds
			var min_x = min(preview_start.x, preview_end.x)
			var max_x = max(preview_start.x, preview_end.x)
			var min_y = min(preview_start.y, preview_end.y)
			var max_y = max(preview_start.y, preview_end.y)
			# Highlight cells in rect, clear others
			for child in grid_display.get_children():
				if child.has_method("get_cell_position"):
					var pos = child.get_cell_position()
					child.highlighted = (
						pos.x >= min_x and pos.x <= max_x and pos.y >= min_y and pos.y <= max_y
					)
	else:
		# Not in rect mode, clear all highlights
		var grid_display = get_tree().get_first_node_in_group("Grid Display")
		if grid_display:
			for child in grid_display.get_children():
				if child.has_method("get_cell_position"):
					child.highlighted = false


func _on_toggle_input_pressed():
	is_collapsed = !is_collapsed
	
	if is_collapsed:
		# Hide all inputs except the toggle button
		for child in vbox_container.get_children():
			if child != toggle_input.get_parent():
				child.visible = false
		
		# Resize container to fit just the toggle button
		margin_container.size.x = 50
		margin_container.position.x += 180
		toggle_input.text = "[ < ]"
	else:
		# Show all inputs
		for child in vbox_container.get_children():
			child.visible = true
		
		# Restore original size
		margin_container.size.x = 227
		margin_container.position.x -= 180
		toggle_input.text = "[ > ]"
		# Stick to right edge
		offset_left = -227


func _on_clear_grid_pressed():
	# Get the grid display node
	var grid_display = get_tree().get_first_node_in_group("Grid Display")
	if not grid_display: return

	# Set all cell values to -1 (only check for get_cell_position method)
	for child in grid_display.get_children():
		if child.has_method("get_cell_position"):
			child.cell_value = -1


func _on_draw_rect_pressed():
	current_tool_mode = ToolMode.RECT
	draw_rect_button.modulate = Color(0.7, 1, 0.7)
	draw_brush_button.modulate = Color(1, 1, 1)


func _on_draw_brush_pressed():
	current_tool_mode = ToolMode.BRUSH
	draw_brush_button.modulate = Color(0.7, 1, 0.7)
	draw_rect_button.modulate = Color(1, 1, 1)


# Helper to find the grid position of the nearest cell to a given mouse position
func _get_nearest_cell_grid_pos(_mouse_pos: Vector2) -> Vector2i:
	# Use the global mouse position in world coordinates
	var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var grid_display = get_tree().get_first_node_in_group("Grid Display")
	if not grid_display: return Vector2i(-1, -1)
	var min_dist = INF
	var nearest_pos = Vector2i(-1, -1)
	for child in grid_display.get_children():
		if child.has_method("get_cell_position"):
			var dist = child.global_position.distance_to(mouse_pos)
			if dist < min_dist:
				min_dist = dist
				nearest_pos = child.get_cell_position()
	return nearest_pos


# Input handling for rectangle drawing
func _input(event):
	if current_tool_mode == ToolMode.RECT:
		# Only handle if mouse is not over UI
		var mouse_focus = get_viewport().gui_get_hovered_control()
		if mouse_focus:
			return
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					# Mouse down: find nearest cell
					var grid_pos = _get_nearest_cell_grid_pos(event.position)
					if grid_pos != Vector2i(-1, -1):
						rect_start = grid_pos
						is_rect_drawing = true
				elif is_rect_drawing and not event.pressed:
					# Mouse up: find nearest cell and fill
					var grid_pos = _get_nearest_cell_grid_pos(event.position)
					if grid_pos != Vector2i(-1, -1):
						rect_end = grid_pos
						_fill_rect(rect_start, rect_end)
					is_rect_drawing = false


# Rectangle fill implementation
func _fill_rect(start: Vector2i, end: Vector2i):
	# Get selected cell type from Cell Selection
	var cell_selection = get_tree().get_first_node_in_group("Cell Selection")
	if not cell_selection or not cell_selection.has_method("get_selected_cell_type"): return
	var selected_value = cell_selection.get_selected_cell_type()

	# Get grid display
	var grid_display = get_tree().get_first_node_in_group("Grid Display")
	if not grid_display: return

	# Calculate rectangle bounds
	var min_x = min(start.x, end.x)
	var max_x = max(start.x, end.x)
	var min_y = min(start.y, end.y)
	var max_y = max(start.y, end.y)

	# Paint all cells in the rectangle
	for child in grid_display.get_children():
		if child.has_method("get_cell_position"):
			var pos = child.get_cell_position()
			if pos.x >= min_x and pos.x <= max_x and pos.y >= min_y and pos.y <= max_y:
				child.cell_value = selected_value

	# Clear highlights after fill
	for child in grid_display.get_children():
		if child.has_method("get_cell_position"):
			child.highlighted = false

	await get_tree().process_frame  # Ensure UI updates immediately
