extends Node

# Dictionary to store pools: { "scene_path": [Array of available instances] }
var pools = {}

# Dictionary to store active instances and their scene paths for easy return
var active_objects = {}

func get_instance(scene: PackedScene) -> Node:
	var path = scene.resource_path
	if not pools.has(path):
		pools[path] = []
	
	var instance: Node
	if pools[path].size() > 0:
		instance = pools[path].pop_back()
		if instance.has_method("on_reuse"):
			instance.on_reuse()
	else:
		instance = scene.instantiate()
		active_objects[instance.get_instance_id()] = path
		
	return instance

func return_instance(instance: Node):
	var id = instance.get_instance_id()
	if not active_objects.has(id):
		instance.queue_free()
		return

	var path = active_objects[id]

	if pools.has(path) and instance in pools[path]:
		return

	if instance.has_method("on_return"):
		instance.on_return()

	if instance.get_parent():
		instance.get_parent().remove_child(instance)

	pools[path].append(instance)

func cleanup_pool(path: String):
	if pools.has(path):
		for instance in pools[path]:
			instance.queue_free()
		pools.erase(path)
