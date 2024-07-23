class_name Util

## Safely removes the child from the scene
static func free_node(node: Node):
	Console.log({"message": "Removing %s" % node.name, "verbose": true})
	node.get_parent().remove_child(node); 
	node.queue_free()

static func clear_children(parent: Node):
	for child: Node in parent.get_children():
		parent.remove_child(child); child.queue_free()
		continue
	await parent.get_tree().process_frame

static func clear_children_node_2d(parent: Node):
	var filtered_children = parent.get_children().filter(func(c): return c is Node2D)
	for n: Node2D in filtered_children:
		parent.remove_child(n); n.queue_free()
		continue
	await parent.get_tree().process_frame

static func get_node_2d_children(root: Node2D) -> Array:
	return root.get_children().filter(func(c): return c is Node2D)

static func get_game_audio_stream_pos(stream_player: AudioStreamPlayer) -> float:
	return stream_player.get_playback_position()\
	+ AudioServer.get_time_since_last_mix()\
	- AudioServer.get_output_latency()
