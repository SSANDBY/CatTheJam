extends Control

@onready var title_label = $CenterContainer/VBoxContainer/Title
@onready var welcome_label = $CenterContainer/VBoxContainer/WelcomeLabel

func _ready():
	welcome_label.text = "Welcome, " + Api42.current_login + "!"

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_leaderboard_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Leaderboard.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
