class_name BrushSelectionClass extends Control
# Is in group "Brush Selection"

signal cell_type_selected(cell_type: int)

@onready var brush_cell_name = $"HBoxContainer/Brush Cell Name"
@onready var select_brush_cell = $"HBoxContainer/Select Brush Cell"

var cell_type_value: int = -1
var is_selected: bool = false
var pending_cell_info: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect the button press signal
	if select_brush_cell:
		select_brush_cell.pressed.connect(_on_select_brush_cell_pressed)
	
	# If we have pending cell info, set it up now
	if not pending_cell_info.is_empty():
		setup_cell(pending_cell_info)
		pending_cell_info.clear()

# Set up the brush selection cell with cell type data
func setup_cell(cell_info: Dictionary):
	# If the node isn't ready yet, store the info and set it up in _ready
	if not is_inside_tree() or not brush_cell_name or not select_brush_cell:
		pending_cell_info = cell_info
		return
	
	cell_type_value = cell_info.value
	
	# Set the text safely
	if brush_cell_name:
		brush_cell_name.text = cell_info.name
		brush_cell_name.placeholder_text = cell_info.name
	
	# Set the button color to match the cell type color
	if select_brush_cell:
		select_brush_cell.modulate = cell_info.color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_select_brush_cell_pressed():
	# Emit signal with the selected cell type
	cell_type_selected.emit(cell_type_value)
	print("Selected cell type: ", Global.get_cell_string(cell_type_value))

# Get the cell type value for this brush selection
func get_cell_type_value() -> int:
	return cell_type_value

# Set selection state (for visual feedback)
func set_selected(selected: bool):
	is_selected = selected
	# You can add visual feedback here if needed
	# For example, changing the button style or adding a border
