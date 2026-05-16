extends Node2D

@export var laser_scene: PackedScene = preload("res://scenes/Laser.tscn")
@export var warning_time = 1.0
@export var attack_cooldown = 3.0

var player = null
var is_aiming = false
var timer = 0.0

@onready var warning_line = $WarningLine
@onready var visual = $Visual

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	warning_line.visible = false
	timer = randf_range(1.0, 2.0) # Initial delay before first attack

func _process(delta):
	if not player: return
	
	# Rotate towards player
	look_at(player.global_position)
	
	timer -= delta
	if timer <= 0:
		if not is_aiming:
			start_aiming()
		else:
			fire_laser()

func start_aiming():
	is_aiming = true
	timer = warning_time
	warning_line.visible = true
	# Visual feedback: flash or change color
	visual.modulate = Color(1, 0, 0)

func fire_laser():
	is_aiming = false
	timer = attack_cooldown
	warning_line.visible = false
	visual.modulate = Color(1, 1, 1)
	
	# Spawn laser
	var laser = laser_scene.instantiate()
	laser.global_position = global_position
	laser.global_rotation = global_rotation
	get_parent().add_child(laser)
	
	# Destroy itself after firing as requested
	queue_free()
