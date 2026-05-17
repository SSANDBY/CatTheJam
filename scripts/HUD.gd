extends CanvasLayer

@onready var score_label = $ScoreLabel
@onready var energy_bar = $EnergyBar

var score = 0.0

func _process(delta):
	score += 10.0 * delta
	score_label.text = "SCORE: " + str(int(score))

func update_energy(value, max_value):
	energy_bar.value = (value / max_value) * 100
