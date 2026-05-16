extends Area2D

@export var speed = 1500.0
var velocity = Vector2.ZERO

func _ready():
	velocity = Vector2.RIGHT.rotated(global_rotation) * speed
	# Auto-destroy after some time
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _process(delta):
	global_position += velocity * delta

func _on_body_entered(body):
	if body.name == "Player":
		if body.is_shielding:
			queue_free()
			return
		print("Player hit by laser!")
		get_tree().reload_current_scene()
