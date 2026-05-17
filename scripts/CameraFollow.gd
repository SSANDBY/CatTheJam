extends Camera2D

@export var target_node_path: NodePath
@export var smooth_speed: float = 10.0
@onready var target = get_node_or_null(target_node_path)
@onready var camera_3d = get_tree().root.find_child("Camera3D", true, false)

@export var follow_offset: Vector2 = Vector2(0, 0) 


func _process(delta):
	if not target:
		target = get_node_or_null(target_node_path)
		return
	
	# Smoothly follow player position with offset
	var target_pos = target.global_position + follow_offset
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	
	# Sync 3D Camera with 2D position (Angled X-Z Mapping)
	if camera_3d:
		camera_3d.global_position.x = global_position.x
		# Karakteri merkezlemek için: Kamera Z'si = Karakter Y'si + Kamera Y yüksekliği (45 derece açı için)
		camera_3d.global_position.z = global_position.y + 500
		camera_3d.global_position.y = 500 # Yüksekliği sabit tutalım
