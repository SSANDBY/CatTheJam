extends Node2D

@export var texture_atlas: Texture2D = preload("res://models/asteroid1.png")
@export var h_frames: int = 7
@export var v_frames: int = 7

@export var min_speed: float = 50.0
@export var max_speed: float = 200.0

var velocity: Vector2
var has_fire: bool = true

func _ready():
	if not has_fire:
		$Trail.emitting = false
		$Trail.visible = false
		
	$Sprite2D.texture = texture_atlas
	$Sprite2D.hframes = h_frames
	$Sprite2D.vframes = v_frames
	$Sprite2D.frame = randi() % (h_frames * v_frames)
	
	rotation = randf() * TAU
	
	var speed = randf_range(min_speed, max_speed)
	# Main direction: towards bottom-left
	var dir = Vector2(-1, 1).normalized()
	dir = dir.rotated(randf_range(-0.3, 0.3))
	velocity = dir * speed
	
	# Randomize scale
	var s = randf_range(0.2, 0.6)
	scale = Vector2(s, s)
	
	# Gerçekçi Ateş Gradyanı (Gradient)
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.9, 0.2, 1.0)) # Merkezde parlak sarı/turuncu
	grad.set_color(1, Color(1.0, 0.2, 0.0, 0.0)) # Dışa doğru kırmızıya dönüp yok oluyor
	$Trail.color_ramp = grad
	
	$Trail.amount = 80 # Daha yoğun
	$Trail.spread = 25.0
	$Trail.initial_velocity_min = 10.0
	$Trail.initial_velocity_max = 40.0
	$Trail.angle_min = 0.0
	$Trail.angle_max = 360.0
	
	# Parçacıklar kare olduğu için (doku olmadığı için) küçük ve dönen kıvılcımlar gibi ayarlıyoruz
	var scale_multiplier = s / 0.2
	$Trail.scale_amount_min = 4.0 * scale_multiplier
	$Trail.scale_amount_max = 12.0 * scale_multiplier
	$Trail.emission_sphere_radius = 12.0 * scale_multiplier
	
	# Büyük taşlarda alevlerin geriye doğru DAHA UZUN bir iz bırakması için:
	$Trail.lifetime = 0.4 * scale_multiplier
	$Trail.amount = int(60 * scale_multiplier) # Uzayan ize yetecek kadar yoğunluk
	
	# Çıkış noktasını geriye alma
	$Trail.position = -dir * (40.0 * s)
	
	# Cleanup
	await get_tree().create_timer(25.0).timeout
	queue_free()

func _process(delta):
	position += velocity * delta
	$Sprite2D.rotation += 1.0 * delta # Spin
