extends Node2D

@export var meteor_scene: PackedScene = preload("res://scenes/Meteor.tscn")
@export var spawn_interval: float = 0.5

var timer = 0.0

func _ready():
	# Initial burst so screen isn't empty at start
	for i in range(20):
		spawn_meteor(true)

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		spawn_meteor(false)

func spawn_meteor(random_position_on_screen: bool):
	if not meteor_scene: return
	var m = meteor_scene.instantiate()
	
	# Skora göre alev olasılığı
	var fire_prob = 0.05 # Başlangıçta sadece %5 ihtimalle alevli
	var hud = get_parent().get_node_or_null("HUD")
	if hud and "score" in hud:
		# Skor arttıkça (örn. skor 100 olduğunda) olasılık %85'lere kadar çıkar
		fire_prob = clamp(0.05 + (hud.score / 125.0), 0.0, 1.0)
	
	m.has_fire = randf() < fire_prob
	
	if random_position_on_screen:
		# Spawn anywhere within view
		m.position = Vector2(randf_range(-500, 1500), randf_range(-500, 1200))
	else:
		# Spawn slightly outside the top/right mostly
		m.position = Vector2(randf_range(500, 2000), randf_range(-800, -200))
		
	add_child(m)
