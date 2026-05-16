extends CPUParticles2D

@export var texture_atlas: Texture2D = preload("res://models/asteroid1.png")
@export var h_frames: int = 7
@export var v_frames: int = 7

var particles_data = {}

func _ready():
	# Set texture immediately
	texture = texture_atlas
	
	# Create and configure material
	var mat = CanvasItemMaterial.new()
	mat.particles_animation = true
	mat.particles_anim_h_frames = h_frames
	mat.particles_anim_v_frames = v_frames
	mat.particles_anim_loop = false
	self.material = mat
	
	# Random frame selection
	anim_offset_min = 0.0
	anim_offset_max = 1.0
	anim_speed_min = 0.0
	anim_speed_max = 0.0
	
	# Reset particles to apply new material/texture settings immediately
	emitting = true
	restart()
	
	# If they are still invisible, maybe they are too small? 
	# Let's ensure scale is visible (though it's usually set in the inspector)
	# scale_amount_min = 5.0
	# scale_amount_max = 15.0
	
	# Ensure visibility - remove any dark modulation
	modulate = Color(1, 1, 1, 1)
	self_modulate = Color(1, 1, 1, 1)
