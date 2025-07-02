extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	# Update button text to show current save path
	update_button_text()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_pressed():
	open_directory_dialog()


func open_directory_dialog():
	# Create directory dialog
	var dir_dialog = FileDialog.new()
	dir_dialog.title = "Select Save Directory"
	dir_dialog.access = FileDialog.ACCESS_FILESYSTEM
	dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	
	# Add to scene tree temporarily
	get_tree().root.add_child(dir_dialog)
	
	# Connect signals
	dir_dialog.dir_selected.connect(_on_directory_selected)
	dir_dialog.canceled.connect(_on_directory_dialog_canceled)
	
	# Show dialog
	dir_dialog.popup_centered()


func _on_directory_selected(path: String):
	print("Selected directory: ", path)
	
	# Update Global custom save path
	Global.custom_save_path = path
	
	# Update button text to show the new path
	update_button_text()
	
	# Clean up dialog
	var dir_dialog = get_tree().root.get_node_or_null("FileDialog")
	if dir_dialog:
		dir_dialog.queue_free()


func _on_directory_dialog_canceled():
	print("Directory selection canceled")
	
	# Clean up dialog
	var dir_dialog = get_tree().root.get_node_or_null("FileDialog")
	if dir_dialog:
		dir_dialog.queue_free()


func update_button_text():
	var current_path = Global.custom_save_path
	if current_path.is_empty():
		text = "[Path: Downloads]"
	else:
		# Show just the directory name, not the full path
		var dir_name = current_path.get_file()
		if dir_name.is_empty():
			# If get_file() returns empty, try getting the last part of the path
			var path_parts = current_path.split("/")
			if path_parts.size() > 0:
				dir_name = path_parts[-1]
			else:
				dir_name = "Custom"
		
		text = "[ Path: " + dir_name + "]"
