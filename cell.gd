extends Node2D
@onready var sprite = $Sprite2D
@onready var area = $Area2D
@onready var label = $DEBUG_Label
@onready var cell_type = $"Cell Type"

var cell_selected: bool = false
var cell_hovered: bool = false
var cell_value: int = -1

func _ready() -> void: pass

func _process(delta):
	label.text = str(cell_value)
	cell_type.hide()
	if cell_value >= 0: 
		cell_type.show()
		cell_type.frame = cell_value

func get_cell_position() -> Vector2i:
	# Convert world position to grid coordinates
	var grid_x = int(position.x / Global.cell_size)
	var grid_y = int(position.y / Global.cell_size)
	return Vector2i(grid_x, grid_y)

func get_cell_color() -> Color:
	return Global.get_cell_color(cell_value)

func _input(event: InputEvent) -> void:
	# Only handle clicks if we're hovering over this cell
	if cell_hovered:
		# Left click with selected cell type
		if event.is_action_pressed("mouse left"):
			var cell_selection = get_tree().get_first_node_in_group("Cell Selection")
			if cell_selection and cell_selection.has_method("get_selected_cell_type"):
				cell_value = cell_selection.get_selected_cell_type()
		
		# Right click sets to empty
		elif event.is_action_pressed("mouse right"):
			cell_value = Global.cell_types[0].value  # EMPTY value

func _on_mouse_entered() -> void:
	cell_hovered = true
	sprite.frame = 0

func _on_mouse_exited() -> void:
	cell_hovered = false
	sprite.frame = 1
