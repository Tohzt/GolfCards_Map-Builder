extends Node2D
@onready var sprite = $Sprite2D
@onready var area = $Area2D
@onready var label = $DEBUG_Label
@onready var cell_type = $"Cell Type"
@onready var cell_highlight = $"Cell Highlight"

var cell_selected: bool = false
var cell_hovered: bool = false
var cell_value: int = -1
var highlighted: bool = false
var _last_highlighted: bool = false
var _last_cell_value: int = -1

func _ready() -> void:
	cell_highlight.hide()

func _process(_delta: float):
	label.text = str(cell_value)
	cell_type.hide()
	if cell_value >= 0:
		cell_type.show()
		cell_type.frame = 5 # Always use the white frame
		cell_type.modulate = GlobalClass.get_cell_color(cell_value)

	# Auto-clear highlight if mouse is not pressed and not in rect draw mode
	if highlighted:
		var tools = get_tree().get_first_node_in_group("Tools")
		var mouse_left_down = Input.is_action_pressed("mouse left")
		var in_rect_mode = false
		if tools and tools.has_method("get"):
			in_rect_mode = tools.get("current_tool_mode") == tools.ToolMode.RECT and tools.get("is_rect_drawing")
		if not mouse_left_down and not in_rect_mode:
			highlighted = false

	# Highlight visual using Cell_Highlight sprite
	if highlighted:
		cell_highlight.show()
		# Get the selected cell type color (from Cell Selection)
		var cell_selection = get_tree().get_first_node_in_group("Cell Selection")
		var color = Color(1, 1, 0.5, 0.7) # fallback yellowish, semi-transparent
		if cell_selection and cell_selection.has_method("get_selected_cell_type"):
			var selected_type = cell_selection.get_selected_cell_type()
			color = GlobalClass.get_cell_color(selected_type).lerp(Color(1,1,1,1), 0.3)
			color.a = 0.7  # Make sure it's semi-transparent
		cell_highlight.modulate = color
	else:
		cell_highlight.hide()
	# Debug print (only when values change)
	if highlighted != _last_highlighted or cell_value != _last_cell_value:
		_last_highlighted = highlighted
		_last_cell_value = cell_value
	
	# Handle painting when hovering and mouse is held down
	if cell_hovered:
		# Only allow painting if tool mode is brush
		var tools = get_tree().get_first_node_in_group("Tools")
		if tools and tools.has_method("get") and tools.get("current_tool_mode") == tools.ToolMode.BRUSH:
			if Input.is_action_pressed("mouse left"):
				var cell_selection = get_tree().get_first_node_in_group("Cell Selection")
				if cell_selection and cell_selection.has_method("get_selected_cell_type"):
					var selected_value = cell_selection.get_selected_cell_type()
					cell_value = selected_value
			elif Input.is_action_pressed("mouse right"):
				cell_value = Global.cell_types[0].value  # EMPTY value

func get_cell_position() -> Vector2i:
	# Convert world position to grid coordinates
	var grid_x = int(position.x / Global.cell_size)
	var grid_y = int(position.y / Global.cell_size)
	return Vector2i(grid_x, grid_y)

func get_cell_color() -> Color:
	return GlobalClass.get_cell_color(cell_value)

func _input(event: InputEvent) -> void:
	# Only handle clicks if we're hovering over this cell
	if cell_hovered:
		# Only allow painting if tool mode is brush
		var tools = get_tree().get_first_node_in_group("Tools")
		if tools and tools.has_method("get") and tools.get("current_tool_mode") == tools.ToolMode.BRUSH:
			# Left click with selected cell type
			if event.is_action_pressed("mouse left"):
				var cell_selection = get_tree().get_first_node_in_group("Cell Selection")
				if cell_selection and cell_selection.has_method("get_selected_cell_type"):
					var selected_value = cell_selection.get_selected_cell_type()
					cell_value = selected_value
			# Right click sets to empty
			elif event.is_action_pressed("mouse right"):
				cell_value = Global.cell_types[0].value  # EMPTY value

func _on_mouse_entered() -> void:
	cell_hovered = true
	sprite.frame = 0

func _on_mouse_exited() -> void:
	cell_hovered = false
	sprite.frame = 1
