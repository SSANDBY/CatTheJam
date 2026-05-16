extends Node

@export var model_scene: PackedScene
@export var rotation_offset: float = 0.0
@export var follow_2d_rotation: bool = true # Karakterler yönüne baksın mı?
@export var is_flat: bool = false
@export var auto_rotate_speed: float = 0.0
@export var tilt_amount: float = 0.0 # 0 ise tilt yapmaz
@export var tilt_speed: float = 5.0

var proxy: Node3D
var current_rotation: float = 0.0
var current_tilt: float = 0.0

func _ready():
	var world = get_tree().root.find_child("World3D", true, false)
	if world and model_scene:
		proxy = model_scene.instantiate()
		world.add_child(proxy)
		
		var visual = get_parent().get_node_or_null("Visual")
		if visual:
			visual.visible = false
	else:
		push_warning("Proxy3D: World3D or model_scene missing!")

func _process(delta):
	if proxy and get_parent() is Node2D:
		var p = get_parent()
		
		# YANDAN GÖRÜNÜM (SIDE-VIEW) EŞLEMESİ:
		proxy.global_position = Vector3(p.global_position.x, -p.global_position.y, 0)
		
		if is_flat:
			proxy.rotation.x = deg_to_rad(90)
			current_rotation += auto_rotate_speed * delta
			proxy.rotation.y = current_rotation
		else:
			# Rotasyon Yönetimi
			if follow_2d_rotation:
				proxy.rotation.y = -p.rotation + rotation_offset
			else:
				proxy.rotation.y = rotation_offset # Sabit açı (Player için)
			
			# TILT ETKİSİ
			if tilt_amount != 0.0:
				var target_tilt = 0.0
				var velocity_x = 0.0
				if "velocity" in p:
					velocity_x = p.velocity.x
				
				target_tilt = clamp(velocity_x / 400.0, -1.0, 1.0) * tilt_amount
				current_tilt = lerp(current_tilt, target_tilt, delta * tilt_speed)
				proxy.rotation.z = current_tilt

func _exit_tree():
	if proxy:
		proxy.queue_free()
