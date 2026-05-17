extends Node3D

func _ready():
	var anim_player = find_child("AnimationPlayer", true, false)
	if anim_player:
		var anims = anim_player.get_animation_list()
		for a in anims:
			if "Walk" in a or "walk" in a or (a != "RESET" and not "Pose" in a):
				var anim = anim_player.get_animation(a)
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
				anim_player.play(a)
				break
