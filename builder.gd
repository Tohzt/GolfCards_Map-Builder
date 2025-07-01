class_name BuilderClass extends Node2D
@onready var camera = $Camera2D
@onready var grid_display = $"Grid Display"

# Zoom settings
var min_zoom: float = 0.1
var max_zoom: float = 3.0
var zoom_speed: float = 0.1

# Panning settings
var is_panning: bool = false
var pan_start_pos: Vector2
var pan_initial_camera_pos: Vector2

func _ready() -> void:
	# Set initial zoom
	camera.zoom = Vector2.ONE

func _input(event: InputEvent) -> void:
	# Handle zoom in
	if event.is_action_pressed("zoom in"):
		zoom_camera(1.0)
	
	# Handle zoom out
	if event.is_action_pressed("zoom out"):
		zoom_camera(-1.0)
	
	# Handle panning start
	if event.is_action_pressed("zoom drag"):
		is_panning = true
		pan_start_pos = get_global_mouse_position()
		pan_initial_camera_pos = camera.global_position
	
	# Handle panning end
	if event.is_action_released("zoom drag"):
		is_panning = false

func _process(delta: float) -> void:
	# Handle panning movement
	if is_panning:
		var current_mouse_pos = get_global_mouse_position()
		var total_mouse_delta = current_mouse_pos - pan_start_pos
		
		# Calculate target position
		var target_position = pan_initial_camera_pos - total_mouse_delta
		
		# Lerp to the target position for smooth movement
		camera.global_position = camera.global_position.lerp(target_position, 0.8)

func zoom_camera(direction: float) -> void:
	# Get mouse position in world coordinates
	var mouse_pos = get_global_mouse_position()
	
	# Calculate new zoom level
	var zoom_factor = 1.0 + (direction * zoom_speed)
	var new_zoom = camera.zoom * zoom_factor
	
	# Clamp zoom between min and max values
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	
	# Calculate how much the zoom changed
	var zoom_change = new_zoom / camera.zoom
	
	# Adjust camera position to zoom towards mouse
	var camera_pos = camera.global_position
	var mouse_to_camera = mouse_pos - camera_pos
	var new_mouse_to_camera = mouse_to_camera * zoom_change
	var camera_offset = new_mouse_to_camera - mouse_to_camera
	
	# Apply the new zoom and position
	camera.zoom = new_zoom
	camera.global_position += camera_offset
