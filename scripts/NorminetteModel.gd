extends Node3D

@onready var evil_light = $EvilLight
var time = 0.0

func _process(delta):
	time += delta * 8.0
	var pulse = (sin(time) + 1.0) * 0.5 # 0 ile 1 arasında
	evil_light.light_energy = pulse * 10.0
