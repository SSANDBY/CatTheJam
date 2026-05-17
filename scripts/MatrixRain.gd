extends Node2D

var columns = []
var drops = []
var font_size = 20
var screen_width = 1280
var screen_height = 720
var time_accumulator = 0.0
var update_interval = 0.02 

func _ready():
	var num_columns = screen_width / font_size
	for i in range(num_columns):
		columns.append(i * font_size)
		drops.append(randf_range(0, screen_height))

func _process(delta):
	time_accumulator += delta
	if time_accumulator >= update_interval:
		time_accumulator = 0.0
		for i in range(columns.size()):
			drops[i] += font_size * 2.0
			if drops[i] > screen_height and randf() > 0.8:
				drops[i] = 0
		queue_redraw()

func _draw():
	var default_font = ThemeDB.fallback_font
	for i in range(columns.size()):
		for j in range(15):
			var char_val = "1" if randi() % 2 == 0 else "0"
			var y_pos = drops[i] - (j * font_size)
			if y_pos > 0 and y_pos < screen_height:
				var alpha = 1.0 - (j / 15.0)
				var color = Color(0.2, 1.0, 0.2, alpha)
				if j == 0:
					color = Color(0.8, 1.0, 0.8, 1.0)
				draw_string(default_font, Vector2(columns[i], y_pos), char_val, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
