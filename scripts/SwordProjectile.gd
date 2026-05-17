extends Area2D

@export var speed = 800.0
var direction = Vector2.ZERO

func _ready():
	# Auto-destroy after 3 seconds to prevent memory leaks
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	# Optional: if it hits something specific
	pass

func _on_area_entered(area):
	if area.is_in_group("norminettes"):
		area.queue_free()
		# Optional: queue_free() here if sword is destroyed on single hit, or pierce.
		# Let's make it pierce through multiple norminettes for now, or just destroy itself.
		# queue_free()
