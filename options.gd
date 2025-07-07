class_name OptionsClass extends CanvasLayer
# This script is for any of the input/button functionality for this canvaslayer
@onready var input_grid_width = $"MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/Grid Width/Input gridWidth"
@onready var input_grid_height = $"MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/Grid Height/Input gridHeight"
@onready var toggle_input = $"MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/HBoxContainer/Toggle Input"
@onready var margin_container = $"MarginContainer"
@onready var nine_patch_rect = $"MarginContainer/NinePatchRect"
@onready var vbox_container = $"MarginContainer/NinePatchRect/MarginContainer/VBoxContainer"
@onready var map_name = $"MarginContainer/NinePatchRect/MarginContainer/VBoxContainer/Map Name/Map Name"

var is_collapsed: bool = false

func _ready():
	# Set initial values from Global
	input_grid_width.value = Global.grid_width
	input_grid_height.value = Global.grid_height
	
	# Find and connect the reset/resize button by its text
	for child in vbox_container.get_children():
		if child is Button and child.text == "Resize Grid":
			child.pressed.connect(_on_reset_resize_button_pressed)
			break

func _on_toggle_input_pressed():
	is_collapsed = !is_collapsed
	
	if is_collapsed:
		# Hide all inputs except the toggle button
		for child in vbox_container.get_children():
			if child != toggle_input.get_parent():
				child.visible = false
		
		# Resize container to fit just the toggle button
		margin_container.size.x = 50
		toggle_input.text = "[ > ]"
	else:
		# Show all inputs
		for child in vbox_container.get_children():
			child.visible = true
		
		# Restore original size
		margin_container.size.x = 227
		toggle_input.text = "[ < ]"

func _on_reset_resize_button_pressed():
	# Update Global values with input values
	Global.grid_width = int(input_grid_width.value)
	Global.grid_height = int(input_grid_height.value)
	
	# Get reference to the grid display and trigger a rebuild
	var grid_display = get_parent().get_node("../Grid Display")
	if grid_display:
		grid_display.rebuild_grid()

func update_grid_inputs():
	# Update input values to match current Global settings
	input_grid_width.value = Global.grid_width
	input_grid_height.value = Global.grid_height
