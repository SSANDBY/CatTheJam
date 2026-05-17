extends Control

@onready var score_label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel

func _ready():
	var score = GameManager.last_score
	score_label.text = "FINAL SCORE: " + str(score)
	
	status_label.text = "Submitting score..."
	Api42.score_submitted.connect(_on_score_submitted)
	
	# Submit score to Supabase
	Api42.submit_score(
		Api42.current_login,
		Api42.current_login,
		"",
		score
	)

func _on_score_submitted():
	status_label.text = "Score saved online! 🌐"

func _on_restart_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
