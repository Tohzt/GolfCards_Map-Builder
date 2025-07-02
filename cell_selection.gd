extends MarginContainer

signal cell_type_selected(cell_type: int)

var selected_cell_type: int = Global.cell_types[1].value  # Default to Base (index 1)
var brush_selection_cells: Array[BrushSelectionClass] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	create_cell_selection_grid()

func create_cell_selection_grid():
	# Create a VBoxContainer for the cell selection
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(200, 150)
	add_child(vbox)
	
	# Add a label
	var label = Label.new()
	label.text = "Cell Types:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	# Create a VBoxContainer for the brush selection cells
	var brush_container = VBoxContainer.new()
	brush_container.custom_minimum_size = Vector2(200, 120)
	brush_container.add_theme_constant_override("separation", 36)  # Set gap to 36
	vbox.add_child(brush_container)
	
	# Create brush selection cells for each cell type using the Global configuration
	for cell_info in Global.cell_types:
		# Load the brush selection cell scene
		var brush_cell_scene = preload("res://Brush Stuff/brush_selection_cell.tscn")
		var brush_cell = brush_cell_scene.instantiate() as BrushSelectionClass
		
		# Add the brush cell to the scene tree first
		brush_container.add_child(brush_cell)
		brush_selection_cells.append(brush_cell)
		
		# Connect the cell type selected signal
		brush_cell.cell_type_selected.connect(_on_brush_cell_type_selected)
		
		# Set up the brush cell with cell type data (after adding to scene tree)
		brush_cell.setup_cell(cell_info)
	
	# Select the Base brush cell by default (index 1)
	if brush_selection_cells.size() > 1:
		brush_selection_cells[1].set_selected(true)
		selected_cell_type = Global.cell_types[1].value
		cell_type_selected.emit(selected_cell_type)

func _on_brush_cell_type_selected(cell_type: int):
	selected_cell_type = cell_type
	cell_type_selected.emit(selected_cell_type)
	print("Selected cell type: ", Global.get_cell_string(selected_cell_type))

func get_selected_cell_type() -> int:
	return selected_cell_type

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
