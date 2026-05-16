extends Node

@export var model_scene: PackedScene
# Bu offset, modelin .glb içindeki yönüne göre değişir.
# -p.rotation + 1.5708 formülü ile Sağ=Sağ, Sol=Sol, Aşağı=Ön, Yukarı=Arka olmasını sağlar.
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
		proxy.global_position = Vector3(p.global_position.x, 0, p.global_position.y)
		
		# Matematiksel Kesin Çözüm:
		# 2D rotasyonun tersini alıp offset ekliyoruz.
		proxy.rotation.y = -p.rotation + rotation_offset

func _exit_tree():
	if proxy:
		proxy.queue_free()
