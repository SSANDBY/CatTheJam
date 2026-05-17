extends Control

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var login_button: Button = $CenterContainer/VBoxContainer/LoginButton

func _ready():
	# If running from Editor, skip login for easier testing
	if OS.has_feature("editor"):
		print("Editor detected: Bypassing login.")
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
		return

	# Connect Api42 signals
	Api42.me_loaded.connect(_on_me_loaded)
	Api42.api_error.connect(_on_error)
	Api42.token_ready.connect(_on_token_ready)
	
	# Check if we are returning from OAuth (for Web)
	Api42.check_oauth_return()
	
	# Initial UI state
	status_label.text = "WELCOME TO CAT THE JAM\nPlease login with 42 to start the descent."

func _input(event):
	# ESC to close the game
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE):
		get_tree().quit()

func _on_login_button_pressed():
	login_button.disabled = true
	status_label.text = "Login window opened..."
	Api42.login()
	
	# Start polling for code (for Popup mode)
	var timer = get_tree().create_timer(1.0)
	while login_button.disabled:
		Api42.check_oauth_return()
		await get_tree().create_timer(0.5).timeout

func _on_token_ready(_token: String):
	status_label.text = "Authenticating..."

func _on_me_loaded(data: Dictionary):
	var login = data.get("login", "unknown")
	status_label.text = "Hello, " + login + "!\nPreparing your mission..."
	
	# Fetch daily logtime to calculate potions
	Api42.fetch_daily_logtime()
	
	# Wait a moment before starting the game
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_error(message: String):
	status_label.text = "Error: " + message
	login_button.disabled = false
	login_button.text = "Try Again"
