extends CPUParticles2D

func _ready():
	emitting = false
	one_shot = false # We'll control emitting manually
	local_coords = false # This is crucial for the trail effect
	schedule_next()

func schedule_next():
	# Wait between 10 to 30 seconds for a more natural cosmic feel
	await get_tree().create_timer(randf_range(10.0, 30.0)).timeout
	
	# Randomize start position
	position = Vector2(randf_range(0, 1280), randf_range(0, 720))
	
	# Very fast and focused direction
	direction = Vector2(randf_range(-1, -0.5), randf_range(0.5, 1)).normalized()
	
	# Trigger a burst of particles that will leave a trail due to local_coords = false
	emitting = true
	# Let it emit for a short duration to create the streak
	await get_tree().create_timer(0.2).timeout
	emitting = false
	
	schedule_next()
