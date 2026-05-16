extends Node2D

@export var norminette_scene: PackedScene = preload("res://scenes/Norminette.tscn")
@export var moulinette_scene: PackedScene = preload("res://scenes/Moulinette.tscn")

@export var base_spawn_rate = 1.5
@export var min_spawn_rate = 0.4
@export var difficulty_curve = 0.05 

var timer = 0.0
var moulinette_timer = 5.0 # Moulinette starts spawning after 5 seconds
var elapsed_time = 0.0

func _process(delta):
	elapsed_time += delta
	timer += delta
	moulinette_timer -= delta
	
	# Norminette spawning
	var current_spawn_rate = max(min_spawn_rate, base_spawn_rate - (elapsed_time * difficulty_curve))
	if timer >= current_spawn_rate:
		spawn_norminette(elapsed_time)
		timer = 0.0
		
	# Moulinette spawning
	if moulinette_timer <= 0:
		spawn_moulinette()
		# Random interval for the next Moulinette
		moulinette_timer = randf_range(8.0, 12.0)

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
