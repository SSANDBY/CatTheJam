extends Camera2D

@export var target_node_path: NodePath
@export var smooth_speed: float = 10.0
@onready var target = get_node_or_null(target_node_path)
@onready var camera_3d = get_tree().root.find_child("Camera3D", true, false)

func _process(delta):
	if not target:
		target = get_node_or_null(target_node_path)
		return
	
	# Smoothly follow player position
	global_position = global_position.lerp(target.global_position, smooth_speed * delta)
	
	# Sync 3D Camera with 2D position (Side-View Mapping)
	if camera_3d:
		camera_3d.global_position.x = global_position.x
		camera_3d.global_position.y = -global_position.y
		# camera_3d.global_position.z = 1000 # Fixed depth

