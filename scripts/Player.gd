extends CharacterBody2D

@export var speed = 400.0
@export var acceleration = 1500.0
@export var friction = 600.0
@export var dash_speed = 1200.0
@export var dash_duration = 0.15

# Orbit & Gravity Variables
var black_hole_pos = Vector2(640, 360) 
var gravity_constant = 8000000.0
var ambient_pull = 200.0 
var max_orbit_radius = 2000.0

@export var target_max_orbit_radius = 220.0
@export var min_orbit_radius = 45.0 

var is_dashing = false
var dash_timer = 0.0

@export var sword_duration = 1.0 # Max 1 second
@export var sword_cooldown = 3.0 # 3 seconds wait
@export var shield_max_energy = 100.0
@export var max_mana = 100.0
@export var mana_regen = 20.0
@export var dash_mana_cost = 33.0
@export var dash_cooldown = 0.5

var is_attacking = false
var attack_timer = 0.0
var attack_cooldown_timer = 0.0
var is_shielding = false
var shield_energy = 100.0
var mana = 100.0
var dash_cooldown_timer = 0.0

var projectile_count = 1
var projectile_speed_mult = 1.0
var projectile_cooldown_mult = 1.0

@onready var sword_area = $SwordArea
@onready var shield_visual = $ShieldVisual
@onready var hud = get_parent().get_node_or_null("HUD")

func _ready():
	if sword_area:
		sword_area.monitoring = false
	shield_visual.visible = false
	
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.9, 0.2, 1.0)) # Parlak sarı/turuncu
	grad.set_color(1, Color(1.0, 0.2, 0.0, 0.0)) # Kırmızıya dönüp silinme
	
	var jetpack_left = get_parent().get_node_or_null("JetpackLayer/JetpackContainer/JetpackLeft")
	var jetpack_right = get_parent().get_node_or_null("JetpackLayer/JetpackContainer/JetpackRight")
	
	if jetpack_left:
		jetpack_left.color_ramp = grad
		jetpack_left.angle_min = 0.0
		jetpack_left.angle_max = 360.0
	if jetpack_right:
		jetpack_right.color_ramp = grad
		jetpack_right.angle_min = 0.0
		jetpack_right.angle_max = 360.0

func _physics_process(delta):
	var jetpack_left = get_parent().get_node_or_null("JetpackLayer/JetpackContainer/JetpackLeft")
	var jetpack_right = get_parent().get_node_or_null("JetpackLayer/JetpackContainer/JetpackRight")
	
	if is_dashing:
		if jetpack_left: 
			jetpack_left.emitting = true
			jetpack_right.emitting = true
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		apply_constraints()
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
		if "update_mana" in hud:
			hud.update_mana(mana, max_mana)
		
		# Update dynamic max_orbit_radius based on score
		var main = get_parent()
		var is_phase_2 = "is_pedago_phase" in main and main.is_pedago_phase
		var is_phase_3 = "is_phase_3" in main and main.is_phase_3
		
		if is_phase_3:
			max_orbit_radius = target_max_orbit_radius * 9.0
		elif is_phase_2:
			max_orbit_radius = target_max_orbit_radius * 3.0
		else:
			# Shrinks from 2000 to 220 between score 0 and 100
			var score_progress = clamp(hud.score / 100.0, 0.0, 1.0)
			max_orbit_radius = lerp(2000.0, target_max_orbit_radius, score_progress)
		
		# Update CenterCircle visual
		var center_circle = get_parent().get_node_or_null("CenterCircle")
		if center_circle:
			# Current scale 0.5 corresponds to target_max_orbit_radius (220)
			var current_scale = (max_orbit_radius / target_max_orbit_radius) * 0.5
			center_circle.scale = Vector2(current_scale, current_scale)

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
	
	# Rotation Logic
	var target_rotation = -PI/2 # Default: Facing "Up/Back"
	if input_vector != Vector2.ZERO:
		target_rotation = input_vector.angle()
	
	# Smoothly interpolate rotation (rotation_speed can be adjusted)
	var rotation_speed = 10.0
	rotation = lerp_angle(rotation, target_rotation, rotation_speed * delta)

	# Z-Depth / Rendering sıralaması (Karakter arkasını dönünce alevler üstte olmalı)
	var facing_away = sin(rotation) < -0.1
	var jetpack_layer = get_parent().get_node_or_null("JetpackLayer")
	if jetpack_layer:
		if facing_away:
			jetpack_layer.layer = 1
		else:
			jetpack_layer.layer = 0

	# Dash check
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	if Input.is_action_just_pressed("dash") and input_vector != Vector2.ZERO:
		if mana >= dash_mana_cost and dash_cooldown_timer <= 0:
			mana -= dash_mana_cost
			dash_cooldown_timer = dash_cooldown
			start_dash(input_vector)
			return

	# Movement logic with inertia
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * speed, acceleration * delta)
		if jetpack_left: 
			jetpack_left.emitting = true
			jetpack_right.emitting = true
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if jetpack_left: 
			jetpack_left.emitting = false
			jetpack_right.emitting = false
	
	# Mana regeneration
	mana = move_toward(mana, max_mana, mana_regen * delta)
	
	# Potion System
	if Input.is_action_just_pressed("potion_mana"):
		if Api42.potions > 0:
			if mana < max_mana:
				Api42.potions -= 1
				mana = max_mana
				if hud: hud.update_potions(Api42.potions)
				show_buff_text("Mana Restored!")
			else:
				show_buff_text("Mana Full!")
		else:
			print("No potions left!")
			
	if Input.is_action_just_pressed("potion_energy"):
		if Api42.potions > 0:
			if shield_energy < shield_max_energy:
				Api42.potions -= 1
				shield_energy = shield_max_energy
				if hud: hud.update_potions(Api42.potions)
				show_buff_text("Energy Restored!")
			else:
				show_buff_text("Energy Full!")
		else:
			print("No potions left!")
	
	# Gravity Logic
	var to_center = black_hole_pos - global_position
	var distance_sq = to_center.length_squared()
	
	# Scale gravity with score
	var main = get_parent()
	var is_phase_2 = "is_pedago_phase" in main and main.is_pedago_phase
	var is_phase_3 = "is_phase_3" in main and main.is_phase_3
	
	var score_factor = 1.0 + (hud.score * 0.02) if hud else 1.0
	if is_phase_2 or is_phase_3:
		score_factor = 1.0

	var gravity_force = (to_center.normalized() * gravity_constant * score_factor) / max(distance_sq, 1000.0)
	var total_pull = gravity_force + (to_center.normalized() * ambient_pull * score_factor)
	
	if is_phase_3:
		total_pull *= 0.1
		
	velocity += total_pull * delta
	
	move_and_slide()
	apply_constraints()

func apply_constraints():
	var to_center = black_hole_pos - global_position
	var distance = to_center.length()
	
	# RESTRICTION ZONE (MIN RADIUS)
	if distance < min_orbit_radius:
		global_position = black_hole_pos - to_center.normalized() * min_orbit_radius
		if velocity.dot(to_center) > 0:
			velocity -= velocity.project(to_center)
	
	# ORBIT CONSTRAINT (MAX RADIUS)
	if distance > max_orbit_radius:
		global_position = black_hole_pos - to_center.normalized() * max_orbit_radius
		if velocity.dot(-to_center) < 0:
			velocity -= velocity.project(-to_center)

func start_dash(direction):
	is_dashing = true
	dash_timer = dash_duration
	velocity = direction * dash_speed

func start_attack():
	var main = get_parent()
	var is_phase_3 = "is_phase_3" in main and main.is_phase_3
	
	is_attacking = true
	attack_timer = sword_duration
	
	if is_phase_3:
		var mouse_pos = get_global_mouse_position()
		var base_direction = (mouse_pos - global_position).normalized()
		var spread_angle = deg_to_rad(15.0)
		
		for i in range(projectile_count):
			var sword_proj = preload("res://scenes/SwordProjectile.tscn").instantiate()
			sword_proj.global_position = global_position
			
			var angle_offset = (i - (projectile_count - 1) / 2.0) * spread_angle
			var final_dir = base_direction.rotated(angle_offset)
			
			sword_proj.direction = final_dir
			sword_proj.rotation = final_dir.angle()
			if "speed" in sword_proj:
				sword_proj.speed *= projectile_speed_mult
				
			get_parent().add_child(sword_proj)
	else:
		if sword_area:
			sword_area.monitoring = true
			sword_area.visible = true

func stop_attack():
	var main = get_parent()
	var is_phase_3 = "is_phase_3" in main and main.is_phase_3
	
	is_attacking = false
	if is_phase_3:
		attack_cooldown_timer = 0.5 * projectile_cooldown_mult
	else:
		attack_cooldown_timer = sword_cooldown
		if sword_area:
			sword_area.monitoring = false
			sword_area.visible = false

func _on_sword_area_area_entered(area):
	if area.is_in_group("norminettes") or area.is_in_group("pedagos"):
		PoolManager.return_instance(area)

func apply_random_buff():
	var buff_types = ["multi", "speed", "firerate", "shield"]
	var chosen = buff_types[randi() % buff_types.size()]
	var text = ""
	
	if chosen == "multi":
		projectile_count += 1
		text = "+1 Projectile!"
	elif chosen == "speed":
		projectile_speed_mult += 0.3
		text = "Faster Projectiles!"
	elif chosen == "firerate":
		projectile_cooldown_mult *= 0.8
		text = "Increased Fire Rate!"
	elif chosen == "shield":
		shield_max_energy += 50.0
		shield_energy = shield_max_energy
		text = "Shield Upgraded!"
		
	show_buff_text(text)

func show_buff_text(text):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(1280, 100)
	label.position = Vector2(0, 200)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 110
	canvas.add_child(label)
	get_tree().root.add_child(canvas)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 150, 2.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.5)
	tween.tween_callback(canvas.queue_free)
