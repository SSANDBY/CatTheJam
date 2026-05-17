extends Control

@onready var score_label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel

func _ready():
	var score = GameManager.last_score
	score_label.text = "FINAL SCORE: " + str(score)
	
	status_label.text = "Checking leaderboard eligibility..."
	Api42.leaderboard_loaded.connect(_on_leaderboard_checked)
	Api42.score_submitted.connect(_on_score_submitted)
	
	# First, fetch current top 10 to compare
	Api42.fetch_leaderboard()

func _on_leaderboard_checked(data: Array):
	# Disconnect to avoid duplicate calls if user re-enters
	if Api42.leaderboard_loaded.is_connected(_on_leaderboard_checked):
		Api42.leaderboard_loaded.disconnect(_on_leaderboard_checked)
		
	var score = GameManager.last_score
	var is_top_10 = false
	
	if data.size() < 10:
		is_top_10 = true
	else:
		# Compare with the 10th score
		var lowest_top_score = data[data.size() - 1].get("score", 0)
		if score > lowest_top_score:
			is_top_10 = true
	
	if is_top_10:
		status_label.text = "Top 10 qualified! Submitting score..."
		Api42.submit_score(
			Api42.current_login,
			Api42.current_login,
			"",
			score
		)
	else:
		status_label.text = "Score did not reach Top 10."

func _on_score_submitted():
	status_label.text = "High score saved online!"

func _on_restart_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_leaderboard_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")
