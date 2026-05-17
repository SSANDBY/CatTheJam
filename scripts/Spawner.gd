extends Node2D

@export var norminette_scene: PackedScene = preload("res://scenes/Norminette.tscn")
@export var moulinette_scene: PackedScene = preload("res://scenes/Moulinette.tscn")
@export var pedago_scene: PackedScene = preload("res://scenes/Pedago.tscn")

@export var base_spawn_rate = 1.5
@export var min_spawn_rate = 0.4
@export var difficulty_curve = 0.05 

var timer = 0.0
var moulinette_timer = 3.0 # Moulinette starts spawning after 3 seconds
var pedago_timer = 8.0 # Pedago starts spawning after 8 seconds
var elapsed_time = 0.0

func _process(delta):
	elapsed_time += delta
	timer += delta
	moulinette_timer -= delta
	
	# Norminette spawning
	var main = get_parent()
	var is_phase_2 = "is_pedago_phase" in main and main.is_pedago_phase
	
	if not is_phase_2:
		var current_spawn_rate = max(min_spawn_rate, base_spawn_rate - (elapsed_time * difficulty_curve))
		if timer >= current_spawn_rate:
			spawn_norminette(elapsed_time)
			timer = 0.0
		
	# Pedago spawning
	var is_looping = "loop_level" in main and main.loop_level > 0
	if not is_phase_2 and not is_looping:
		pedago_timer -= delta
		if pedago_timer <= 0:
			spawn_pedago(elapsed_time)
			pedago_timer = randf_range(10.0, 15.0)
		
	# Moulinette spawning
	if moulinette_timer <= 0:
		spawn_moulinette()
		# Random interval for the next Moulinette
		if is_phase_2:
			spawn_moulinette() # Spawn 2 at once during pedago phase
			moulinette_timer = randf_range(0.5, 1.0)
		else:
			moulinette_timer = randf_range(4.0, 7.0)

func spawn_norminette(time_factor):
	if not norminette_scene: return
	var norminette = norminette_scene.instantiate()

	if norminette.has_method("set_difficulty"):
		norminette.set_difficulty(time_factor)

	var player = get_tree().root.find_child("Player", true, false)
	var spawn_radius = 2000.0 # Fallback default
	if player and "max_orbit_radius" in player:
		spawn_radius = player.max_orbit_radius + 150.0
		
	var angle = randf() * TAU
	var spawn_pos = Vector2(640, 360) + Vector2.RIGHT.rotated(angle) * spawn_radius
	norminette.global_position = spawn_pos
	get_parent().add_child(norminette)


func spawn_moulinette():
	if not moulinette_scene: return
	var moulinette = moulinette_scene.instantiate()
	# Spawn Moulinette at a random point on a circle within view
	var angle = randf() * TAU
	var spawn_dist = 320.0
	moulinette.global_position = Vector2(640, 360) + Vector2.RIGHT.rotated(angle) * spawn_dist
	get_parent().add_child(moulinette)

func spawn_pedago(time_factor):
	if not pedago_scene: return
	var pedago = pedago_scene.instantiate()

	if pedago.has_method("set_difficulty"):
		pedago.set_difficulty(time_factor)

	var player = get_tree().root.find_child("Player", true, false)
	var spawn_radius = 2000.0 # Fallback default
	if player and "max_orbit_radius" in player:
		spawn_radius = player.max_orbit_radius + 150.0
		
	var angle = randf() * TAU
	var spawn_pos = Vector2(640, 360) + Vector2.RIGHT.rotated(angle) * spawn_radius
	pedago.global_position = spawn_pos
	get_parent().add_child(pedago)
