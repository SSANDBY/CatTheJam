extends Node2D

@export var rotation_speed: float = 0.5

func _process(delta):
	rotation += rotation_speed * delta
