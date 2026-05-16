extends CharacterBody2D

@export var speed = 400.0
@export var acceleration = 1500.0
@export var friction = 600.0
@export var dash_speed = 1200.0
@export var dash_duration = 0.15

# Orbit & Gravity Variables
var black_hole_pos = Vector2(640, 360) 
var gravity_constant = 8000000.0
var ambient_pull = 350.0 
@export var max_orbit_radius = 220.0
@export var min_orbit_radius = 45.0 

var is_dashing = false
var dash_timer = 0.0

@export var sword_duration = 1.0 # Max 1 second
@export var sword_cooldown = 3.0 # 3 seconds wait
@export var shield_max_energy = 100.0

var is_attacking = false
var attack_timer = 0.0
var attack_cooldown_timer = 0.0
var is_shielding = false
var shield_energy = 100.0

@onready var sword_area = $SwordArea
@onready var shield_visual = $ShieldVisual
@onready var hud = get_parent().get_node_or_null("HUD")

func _ready():
	sword_area.monitoring = false
	shield_visual.visible = false

func _physics_process(delta):
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		return

	# Shield logic (Right Click or K)
	if (Input.is_action_pressed("defend") or Input.is_key_pressed(KEY_K)) and shield_energy > 0:
		is_shielding = true
		shield_energy -= 40.0 * delta
		shield_visual.visible = true
	else:
		is_shielding = false
		shield_visual.visible = false
		shield_energy = move_toward(shield_energy, shield_max_energy, 5.0 * delta)
	
	if hud:
		hud.update_energy(shield_energy, shield_max_energy)

	# Attack logic (Left Click or J)
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	var is_attack_input = Input.is_action_pressed("attack") or Input.is_key_pressed(KEY_J)
	var is_attack_just_pressed = Input.is_action_just_pressed("attack") or Input.is_key_pressed(KEY_J)

	if is_attack_just_pressed and not is_attacking and attack_cooldown_timer <= 0:
		start_attack()
	
	if is_attacking:
		attack_timer -= delta
		# If 1 second is up OR player releases the button
		if attack_timer <= 0 or not is_attack_input:
			stop_attack()

	# Input handling
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Dash check
	if Input.is_action_just_pressed("dash") and input_vector != Vector2.ZERO:
		start_dash(input_vector)
		return

	# Movement logic with inertia
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
		rotation = velocity.angle()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Gravity Logic
	var to_center = black_hole_pos - global_position
	var distance = to_center.length()
	var distance_sq = distance * distance
	
	# RESTRICTION ZONE
	if distance < min_orbit_radius:
		global_position = black_hole_pos - to_center.normalized() * min_orbit_radius
		if velocity.dot(to_center) > 0:
			velocity -= velocity.project(to_center)

	# Scale gravity with score
	var score_factor = 1.0 + (hud.score * 0.02) if hud else 1.0
	var gravity_force = (to_center.normalized() * gravity_constant * score_factor) / max(distance_sq, 1000.0)
	var total_pull = gravity_force + (to_center.normalized() * ambient_pull * score_factor)
	velocity += total_pull * delta
	
	move_and_slide()
	
	# ORBIT CONSTRAINT
	var final_to_center = black_hole_pos - global_position
	if final_to_center.length() > max_orbit_radius:
		global_position = black_hole_pos - final_to_center.normalized() * max_orbit_radius
		if velocity.dot(-final_to_center) < 0:
			velocity -= velocity.project(-final_to_center)

func start_dash(direction):
	is_dashing = true
	dash_timer = dash_duration
	velocity = direction * dash_speed

func start_attack():
	is_attacking = true
	attack_timer = sword_duration
	sword_area.monitoring = true
	sword_area.visible = true

func stop_attack():
	is_attacking = false
	attack_cooldown_timer = sword_cooldown
	sword_area.monitoring = false
	sword_area.visible = false

func _on_sword_area_area_entered(area):
	if area.is_in_group("norminettes"):
		area.queue_free()
