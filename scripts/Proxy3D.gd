extends Node

@export var model_scene: PackedScene
@export var rotation_offset: float = 1.5708
@export var is_flat: bool = false
@export var auto_rotate_speed: float = 0.0
@export var test_rotation_x: float = 200.0
@export var test_rotation_y: float = 0.0
@export var test_rotation_z: float = 0.0

var proxy: Node3D
var current_rotation: float = 0.0

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
		
		# MERKEZİ PERSPEKTİF KOMPANZASYONU:
		# 2D merkezimiz 360. 3D kameramız da 360'a odaklı.
		# Kayma olmaması için farkı (p.y - 360) hesaplayıp sin(45)'e bölüyoruz.
		var z_offset = (p.global_position.y - 360.0) / 0.707107
		var corrected_z = 360.0 + z_offset
		
		proxy.global_position = Vector3(p.global_position.x, 0, corrected_z)
		
		if is_flat:
			proxy.rotation.x = deg_to_rad(test_rotation_x)
			proxy.rotation.z = deg_to_rad(test_rotation_z)
			
			if auto_rotate_speed != 0.0:
				current_rotation += auto_rotate_speed * delta
				proxy.rotation.y = current_rotation
			else:
				proxy.rotation.y = deg_to_rad(test_rotation_y)
		else:
			# Normal karakterler için
			proxy.rotation.y = -p.rotation + rotation_offset

func _exit_tree():
	if proxy:
		proxy.queue_free()
