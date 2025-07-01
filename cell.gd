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

func _input(event: InputEvent) -> void:
	# Only handle clicks if we're hovering over this cell
	if cell_hovered:
		if event.is_action_pressed("mouse left"):
			cell_value += 1
			# Wrap around to -1 if we exceed the maximum enum value
			if cell_value > Global.CellType.values().max():
				cell_value = -1
		elif event.is_action_pressed("mouse right"):
			cell_value -= 1
			# Wrap around to maximum if we go below -1
			if cell_value < -1:
				cell_value = Global.CellType.values().max()

func _on_mouse_entered() -> void:
	cell_hovered = true
	sprite.frame = 0

func _on_mouse_exited() -> void:
	cell_hovered = false
	sprite.frame = 1
