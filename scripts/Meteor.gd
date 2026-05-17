extends Node2D

@export var texture_atlas: Texture2D = preload("res://models/asteroid1.png")
@export var h_frames: int = 7
@export var v_frames: int = 7

@export var min_speed: float = 50.0
@export var max_speed: float = 200.0

var velocity: Vector2
var has_fire: bool = true

func on_reuse():
	visible = true
	set_process(true)
	init_meteor()

func on_return():
	visible = false
	set_process(false)

func _ready():
	init_meteor()

func init_meteor():
	if not has_fire:
		$Trail.emitting = false
		$Trail.visible = false
	else:
		$Trail.emitting = true
		$Trail.visible = true
		
	$Sprite2D.texture = texture_atlas
	$Sprite2D.hframes = h_frames
	$Sprite2D.vframes = v_frames
	$Sprite2D.frame = randi() % (h_frames * v_frames)
	
	rotation = randf() * TAU
	
	var speed = randf_range(min_speed, max_speed)
	# Main direction: towards bottom-left
	var dir = Vector2(-1, 1).normalized()
	dir = dir.rotated(randf_range(-0.3, 0.3))
	velocity = dir * speed
	
	# Randomize scale
	var s = randf_range(0.2, 0.6)
	scale = Vector2(s, s)
	
	# Gerçekçi Ateş Gradyanı (Gradient)
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.9, 0.2, 1.0)) 
	grad.set_color(1, Color(1.0, 0.2, 0.0, 0.0)) 
	$Trail.color_ramp = grad
	
	$Trail.amount = 80 
	$Trail.spread = 25.0
	$Trail.initial_velocity_min = 10.0
	$Trail.initial_velocity_max = 40.0
	$Trail.angle_min = 0.0
	$Trail.angle_max = 360.0
	
	var scale_multiplier = s / 0.2
	$Trail.scale_amount_min = 4.0 * scale_multiplier
	$Trail.scale_amount_max = 12.0 * scale_multiplier
	$Trail.emission_sphere_radius = 12.0 * scale_multiplier
	
	$Trail.lifetime = 0.4 * scale_multiplier
	$Trail.amount = int(60 * scale_multiplier) 
	
	$Trail.position = -dir * (40.0 * s)
	
	# Lifetime timer
	reset_lifetime()

func reset_lifetime():
	# Cancel previous timer if exists by checking if we're in a pool
	# For pooling, we can use a simple timer in _process
	current_lifetime = 0.0

var current_lifetime = 0.0
var max_lifetime = 25.0

func _process(delta):
	position += velocity * delta
	$Sprite2D.rotation += 1.0 * delta # Spin
	
	current_lifetime += delta
	if current_lifetime >= max_lifetime:
		PoolManager.return_instance(self)
