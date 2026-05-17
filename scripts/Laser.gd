extends Area2D

@export var speed = 1500.0
var velocity = Vector2.ZERO

var lifetime = 2.0
var timer = 0.0

func on_reuse():
	timer = 0.0
	visible = true
	set_process(true)

func on_return():
	visible = false
	set_process(false)

func _ready():
	velocity = Vector2.RIGHT.rotated(global_rotation) * speed

func _process(delta):
	# Update velocity based on rotation if it's not set (for pooled instances)
	if velocity == Vector2.ZERO:
		velocity = Vector2.RIGHT.rotated(global_rotation) * speed
		
	global_position += velocity * delta
	timer += delta
	if timer >= lifetime:
		PoolManager.return_instance(self)

func _on_body_entered(body):
	if body.name == "Player":
		if body.is_shielding:
			PoolManager.return_instance(self)
			return
		print("Player hit by laser!")
		GameManager.game_over()
