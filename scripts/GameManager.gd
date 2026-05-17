extends Node

var is_pedago_phase = false
var alarm_label = null
var alarm_timer = 0.0
var phase_2_end_score = 0.0
var matrix_layer_instance = null
var is_phase_3 = false
var loop_level = 0
var normal_phase_end_score = 0.0
var last_score = 0

func _ready():
	# Set fullscreen on startup
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	# OAuth callback'ten döndüysek code'u yakala
	

func _input(event):
	# ESC to close the game
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE):
		get_tree().quit()

func _process(delta):
	if alarm_timer > 0:
		alarm_timer -= delta
		if alarm_label:
			alarm_label.visible = int(alarm_timer * 8.0) % 2 == 0
		
		if alarm_timer <= 0 and alarm_label:
			if alarm_label.get_parent():
				alarm_label.get_parent().queue_free()
			alarm_label = null
			
	if is_pedago_phase:
		var hud = get_node_or_null("HUD")
		if hud and hud.score >= phase_2_end_score:
			end_phase_2()
			
	if not is_pedago_phase and loop_level > 0:
		var hud = get_node_or_null("HUD")
		if hud and hud.score >= normal_phase_end_score:
			start_phase_2()

var matrix_rain_script = preload("res://scripts/MatrixRain.gd")
var pedago_scene = preload("res://scenes/Pedago.tscn")

func start_phase_2():
	if is_pedago_phase: return
	is_pedago_phase = true
	
	var hud = get_node_or_null("HUD")
	if hud:
		if loop_level == 0:
			phase_2_end_score = hud.score + 100.0
		else:
			phase_2_end_score = hud.score + 50.0
	else:
		phase_2_end_score = 999999.0
	
	var bg_elements = ["Stars", "Meteors", "BlackHole/VisualSprite"]
	for node_path in bg_elements:
		var node = get_node_or_null(node_path)
		if node:
			node.visible = false
			
	matrix_layer_instance = CanvasLayer.new()
	matrix_layer_instance.layer = 0
	matrix_layer_instance.name = "MatrixRainLayer"
	
	var matrix_rain = matrix_rain_script.new()
	matrix_rain.name = "MatrixRain"
	
	matrix_layer_instance.add_child(matrix_rain)
	add_child(matrix_layer_instance)
	
	var circle = get_node_or_null("CenterCircle")
	if circle and matrix_layer_instance:
		move_child(matrix_layer_instance, circle.get_index() + 1)
		
	# Setup Alarm
	alarm_label = Label.new()
	alarm_label.text = "BERKAY CLUSTERDE"
	alarm_label.add_theme_font_size_override("font_size", 96)
	alarm_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
	alarm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alarm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alarm_label.size = Vector2(1280, 720)
	alarm_label.position = Vector2.ZERO
	
	var alarm_canvas = CanvasLayer.new()
	alarm_canvas.layer = 100
	alarm_canvas.add_child(alarm_label)
	add_child(alarm_canvas)
	
	alarm_timer = 3.0
	
	var existing_pedagos = get_tree().get_nodes_in_group("pedagos")
	if existing_pedagos.size() == 0:
		var p = pedago_scene.instantiate()
		p.global_position = Vector2(640, 360)
		p.reached_center = true
		add_child(p)

func end_phase_2():
	if not is_pedago_phase: return
	is_pedago_phase = false
	
	var bg_elements = ["Stars", "Meteors", "BlackHole/VisualSprite"]
	for node_path in bg_elements:
		var node = get_node_or_null(node_path)
		if node:
			node.visible = true
			
	if matrix_layer_instance:
		matrix_layer_instance.queue_free()
		matrix_layer_instance = null
		
	var pedagos = get_tree().get_nodes_in_group("pedagos")
	for p in pedagos:
		p.queue_free()
		
	loop_level += 1
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("apply_random_buff"):
		player.apply_random_buff()
		
	start_phase_3()

func game_over():
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud:
		last_score = int(hud.score)
	
	# Wait a bit then change scene
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
