extends Area2D

@export var speed = 120.0
var black_hole_pos = Vector2(640, 360)
var velocity = Vector2.ZERO
var difficulty_multiplier = 1.0

func set_difficulty(time_factor):
	difficulty_multiplier = 1.0 + (time_factor * 0.025)
	speed *= difficulty_multiplier

func on_reuse():
	reached_center = false
	velocity = Vector2.ZERO
	difficulty_multiplier = 1.0
	speed = 120.0
	visible = true
	monitoring = true
	set_physics_process(true)

func on_return():
	visible = false
	monitoring = false
	set_physics_process(false)

func _ready():
	add_to_group("pedagos")
	init_movement()

func init_movement():
	# Moves exactly towards the center when spawned
	velocity = (black_hole_pos - global_position).normalized() * speed

var reached_center = false
var pulse_time = 0.0

func _physics_process(delta):
	var to_center = black_hole_pos - global_position
	var distance = to_center.length()
	
	if not reached_center:
		global_position += velocity * delta
		rotation = velocity.angle()
		
		var base_scale = clamp(distance / 500.0, 1.5, 4.0)
		scale = Vector2(base_scale, base_scale)
		
		if distance < 15.0:
			reached_center = true
			global_position = black_hole_pos
			var main = get_parent()
			if main and main.has_method("start_phase_2"):
				main.start_phase_2()
	else:
		var player = get_tree().root.find_child("Player", true, false)
		if player:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * (speed * 0.35)
			global_position += velocity * delta
			rotation = velocity.angle()


func _on_body_entered(body):
	if body.name == "Player":
		if "is_shielding" in body and body.is_shielding:
			PoolManager.return_instance(self)
			return

		GameManager.game_over()
