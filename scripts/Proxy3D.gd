extends Node

@export var model_scene: PackedScene
# 45 derecelik kamera açısında (sin(45) = 0.707) 
# 2D Y ekseniyle 3D Z eksenini eşitlemek için gereken offset.
@export var rotation_offset: float = 1.5708
var proxy: Node3D

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

func _process(_delta):
	if proxy and get_parent() is Node2D:
		var p = get_parent()
		
		# PERSPEKTİF KOMPANZASYONU:
		# 45 derecelik açıda Z ekseni ekranda sin(45) kadar kısalır.
		# 2D'deki Y pozisyonunun 3D'de tam aynı yere düşmesi için 
		# Z değerini sin(45)'e bölerek (yaklaşık 1.414 ile çarparak) genişletiyoruz.
		var corrected_z = p.global_position.y / 0.707107
		proxy.global_position = Vector3(p.global_position.x, 0, corrected_z)
		
		# Rotasyon (Yön) eşlemesi
		proxy.rotation.y = -p.rotation + rotation_offset

func _exit_tree():
	if proxy:
		proxy.queue_free()
