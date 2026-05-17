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
	var main = get_tree().root.get_node_or_null("Main")
	var is_phase_3 = main and "is_phase_3" in main and main.is_phase_3
	
	if is_phase_3:
		var player = get_tree().root.find_child("Player", true, false)
		if player:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			
		global_position += velocity * delta
		rotation = velocity.angle()
		scale = Vector2(0.5, 0.5)
		return

	var to_center = black_hole_pos - global_position
	var distance_sq = to_center.length_squared()
	
	if distance_sq > 400:
		var gravity_force = (to_center.normalized() * gravity_constant) / distance_sq
		velocity += gravity_force * delta
	else:
		queue_free()
	
	global_position += velocity * delta
	rotation = velocity.angle()
	
	# DISTANCE SCALING (Shrink as it gets closer to the black hole)
	var distance = to_center.length()
	var base_scale = clamp(distance / 500.0, 0.15, 0.7)
	scale = Vector2(base_scale, base_scale)

func _on_body_entered(body):
	if body.name == "Player":
		if body.is_shielding:
			queue_free()
			return
		print("Player hit by Norminette!")
		get_tree().reload_current_scene()
