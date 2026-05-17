extends Area2D

@export var speed = 800.0
var direction = Vector2.ZERO

var lifetime = 3.0
var timer = 0.0

func on_reuse():
	timer = 0.0
	visible = true
	set_physics_process(true)

func on_return():
	visible = false
	set_physics_process(false)

func _ready():
	pass

func _physics_process(delta):
	global_position += direction * speed * delta
	timer += delta
	if timer >= lifetime:
		PoolManager.return_instance(self)

func _on_body_entered(body):
	# Optional: if it hits something specific
	pass

func _on_area_entered(area):
	if area.is_in_group("norminettes") or area.is_in_group("pedagos"):
		PoolManager.return_instance(area)
		# PoolManager.return_instance(self) # Uncomment if sword should vanish on hit
