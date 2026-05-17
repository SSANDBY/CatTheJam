extends Area2D

@export var speed = 120.0
var black_hole_pos = Vector2(640, 360)
var velocity = Vector2.ZERO
var difficulty_multiplier = 1.0

func set_difficulty(time_factor):
	difficulty_multiplier = 1.0 + (time_factor * 0.025)
	speed *= difficulty_multiplier

func _ready():
	add_to_group("pedagos")
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
		
		var base_scale = clamp(distance / 500.0, 0.4, 1.0)
		scale = Vector2(base_scale, base_scale)
		
		if distance < 15.0:
			reached_center = true
			global_position = black_hole_pos
			var main = get_parent()
			if main.has_method("start_phase_2"):
				main.start_phase_2()
	else:
		# Reached center, now chase player!
		scale = Vector2(2.0, 2.0)
		var player = get_tree().root.find_child("Player", true, false)
		if player:
			var direction = (player.global_position - global_position).normalized()
			# Move a bit slower than its initial speed
			velocity = direction * (speed * 0.7)
			global_position += velocity * delta
			rotation = velocity.angle()


func _on_body_entered(body):
	if body.name == "Player":
		if body.is_shielding:
			queue_free()
			return
		print("Player hit by Pedago!")
		get_tree().reload_current_scene()
