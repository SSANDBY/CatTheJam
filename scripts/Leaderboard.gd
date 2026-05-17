extends Control

@onready var item_container = $CenterContainer/VBoxContainer/ScrollContainer/ItemContainer
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel

func _ready():
	Api42.leaderboard_loaded.connect(_on_leaderboard_loaded)
	status_label.text = "Loading leaderboard..."
	Api42.fetch_leaderboard()
	
	# Fail-safe timeout
	await get_tree().create_timer(5.0).timeout
	if status_label.visible:
		status_label.text = "Failed to load leaderboard. Please try again."

func _on_leaderboard_loaded(data: Array):
	status_label.visible = false
	
	# Clear existing items
	for child in item_container.get_children():
		child.queue_free()
		
	# Add header
	var header = create_item("NICK", "SCORE", true)
	item_container.add_child(header)
	
	for entry in data:
		var login = entry.get("login", "unknown")
		var score = entry.get("score", 0)
		var item = create_item(login, str(score))
		item_container.add_child(item)

func create_item(nick: String, score: String, is_header: bool = false) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size.x = 400
	
	var nick_label = Label.new()
	nick_label.text = nick
	nick_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_header: nick_label.add_theme_color_override("font_color", Color.YELLOW)
	
	var score_label = Label.new()
	score_label.text = score
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if is_header: score_label.add_theme_color_override("font_color", Color.YELLOW)
	
	hbox.add_child(nick_label)
	hbox.add_child(score_label)
	return hbox

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
