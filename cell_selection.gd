class_name CellSelectionClass extends PanelContainer
@onready var vbox = $MarginContainer/TextureRect/ScrollContainer/VBoxContainer

signal cell_type_selected(cell_type: int)

var selected_cell_type: int = Global.cell_types[1].value  # Default to Base (index 1)
var brush_selection_cells: Array[BrushSelectionClass] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	create_cell_selection_grid()

func create_cell_selection_grid():
	if not vbox: return
	
	# Create brush selection cells for each cell type using the Global configuration
	for i in range(Global.cell_types.size()):
		var cell_info = Global.cell_types[i]
		
		# Load the brush selection cell scene
		var brush_cell_scene = Global.BRUSH_TYPES
		var brush_cell = brush_cell_scene.instantiate() as BrushSelectionClass
		
		# Add the brush cell to the scene tree first
		vbox.add_child(brush_cell)
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
	# Deselect all cells first
	for brush_cell in brush_selection_cells:
		brush_cell.set_selected(false)
	
	# Find and select the clicked cell
	for brush_cell in brush_selection_cells:
		if brush_cell.get_cell_type_value() == cell_type:
			brush_cell.set_selected(true)
			break
	
	selected_cell_type = cell_type
	cell_type_selected.emit(selected_cell_type)

func get_selected_cell_type() -> int:
	return selected_cell_type
