extends CanvasLayer

@onready var score_label = $ScoreLabel
@onready var energy_bar = $EnergyBar
@onready var mana_bar = $ManaBar
@onready var nickname_label = $NicknameLabel
@onready var logtime_label = get_node_or_null("LogtimeLabel")
@onready var potion_label = get_node_or_null("PotionLabel")

var score = 0.0

func _ready():
	if nickname_label:
		nickname_label.text = "PLAYER: " + Api42.current_login.to_upper()
	if logtime_label:
		logtime_label.text = "LOGGED IN TODAY: %.2fh" % Api42.current_logtime
	update_potions(Api42.potions)

func _process(delta):
	score += 10.0 * delta
	score_label.text = "SCORE: " + str(int(score))

func update_energy(value, max_value):
	energy_bar.value = (value / max_value) * 100

func update_mana(value, max_value):
	if mana_bar:
		mana_bar.value = (value / max_value) * 100

func update_potions(count):
	if potion_label:
		potion_label.text = "POTIONS: " + str(count) + " (Q/E)"
