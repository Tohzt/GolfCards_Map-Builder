class_name BrushSelectionClass extends Control
# Is in group "Brush Selection"

signal cell_type_selected(cell_type: int)

@onready var brush_cell_name = $"HBoxContainer/Brush Cell Name"
@onready var select_brush_cell = $"HBoxContainer/Select Brush Cell"

var cell_type_value: int = -1
var is_selected: bool = false
var pending_cell_info: Dictionary = {}
var cell_color: Color = Color.WHITE
var outline_panel: PanelContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set proper sizing for this control
	custom_minimum_size = Vector2(180, 32)  # Match the HBoxContainer size from the scene
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Create outline panel
	create_outline_panel()
	
	# If we have pending cell info, set it up now
	if not pending_cell_info.is_empty():
		setup_cell(pending_cell_info)
		pending_cell_info.clear()

func create_outline_panel():
	# Create a PanelContainer for the outline
	outline_panel = PanelContainer.new()
	outline_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse events
	outline_panel.size_flags_horizontal = Control.SIZE_FILL
	outline_panel.size_flags_vertical = Control.SIZE_FILL
	
	# Move the HBoxContainer to be a child of the outline panel
	if has_node("HBoxContainer"):
		var hbox = get_node("HBoxContainer")
		remove_child(hbox)
		outline_panel.add_child(hbox)
		# Ensure the HBoxContainer fills the outline panel
		hbox.size_flags_horizontal = Control.SIZE_FILL
		hbox.size_flags_vertical = Control.SIZE_FILL
		# Set the HBoxContainer to fill the entire outline panel
		hbox.anchors_preset = Control.PRESET_FULL_RECT
	
	add_child(outline_panel)

# Set up the brush selection cell with cell type data
func setup_cell(cell_info: Dictionary):
	# If the node isn't ready yet, store the info and set it up in _ready
	if not is_inside_tree() or not brush_cell_name or not select_brush_cell:
		pending_cell_info = cell_info
		return
	
	cell_type_value = cell_info.value
	cell_color = cell_info.color
	
	# Set the text safely
	if brush_cell_name:
		brush_cell_name.text = cell_info.name
		brush_cell_name.placeholder_text = cell_info.name
	
	# Set the button color to match the cell type color
	if select_brush_cell:
		select_brush_cell.modulate = cell_info.color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
	pass

func _on_select_brush_cell_pressed():
	# Emit signal with the selected cell type
	cell_type_selected.emit(cell_type_value)

# Get the cell type value for this brush selection
func get_cell_type_value() -> int:
	return cell_type_value

# Set selection state (for visual feedback)
func set_selected(selected: bool):
	is_selected = selected
	
	if outline_panel:
		if selected:
			# Create colored outline style
			var outline_style = StyleBoxFlat.new()
			outline_style.bg_color = Color.TRANSPARENT
			outline_style.border_color = cell_color
			outline_style.border_width_left = 3
			outline_style.border_width_right = 3
			outline_style.border_width_top = 3
			outline_style.border_width_bottom = 3
			outline_panel.add_theme_stylebox_override("panel", outline_style)
		else:
			# Remove outline style only
			outline_panel.remove_theme_stylebox_override("panel")
