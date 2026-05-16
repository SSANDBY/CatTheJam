extends Area2D

@export var speed = 100.0
var black_hole_pos = Vector2(640, 360)
var gravity_constant = 300000.0
var velocity = Vector2.ZERO
var difficulty_multiplier = 1.0

func set_difficulty(time_factor):
	difficulty_multiplier = 1.0 + (time_factor * 0.025)
	gravity_constant *= difficulty_multiplier
	speed *= difficulty_multiplier

func _ready():
	add_to_group("norminettes")
	velocity = (black_hole_pos - global_position).normalized() * speed

func _physics_process(delta):
	var to_center = black_hole_pos - global_position
	var distance_sq = to_center.length_squared()
	
	if distance_sq > 400:
		var gravity_force = (to_center.normalized() * gravity_constant) / distance_sq
		velocity += gravity_force * delta
	else:
		queue_free()
	
	global_position += velocity * delta

func _on_body_entered(body):
	if body.name == "Player":
		if body.is_shielding:
			queue_free()
			return
		print("Player hit by Norminette!")
		get_tree().reload_current_scene()
