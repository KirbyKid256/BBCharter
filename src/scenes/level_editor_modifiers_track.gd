extends Node2D

@export var key: String
@export var prefab: PackedScene

func _ready():
	if Editor.project_loaded: load_keyframes()

func load_keyframes():
	if Editor.project_loaded:
		for i in range(1, Config.keyframes[key].size()):
			add_keyframe(Config.keyframes[key][i])
	else:
		LevelEditor.place_init_keyframes(key, self, prefab)

func clear_keyframes():
	for i in range(get_child_count()-1, 0, -1):
		remove_keyframe(get_child(i).data)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func _update_child_order():
	for child in get_children():
		var idx: int = Config.keyframes[key].find(child.data)
		if child.get_index() != idx: move_child(child, idx)

func add_keyframe(data: Dictionary):
	LevelEditor.add_single_keyframe(data, self, prefab)
	if Config.keyframes[key].find(data) < 0:
		Config.keyframes[key].append(data)
		Config.keyframes[key].sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	
	_update_child_order()

func remove_keyframe(data: Dictionary):
	_update_child_order()
	
	var idx: int = Config.keyframes[key].find(data)
	Util.free_node(get_child(idx))
	Config.keyframes[key].remove_at(idx)

func create_keyframe():
	var timestamp = LevelEditor.get_timestamp()
	timestamp = clampf(timestamp, 0, timestamp)
	
	var prev_bpm = Config.keyframes[key].filter(func(a): return timestamp > a['timestamp']).back()
	if prev_bpm == null: prev_bpm = Config.keyframes[key][0]
	
	var new_keyframe_data = {
		'bpm': prev_bpm.bpm,
		'timestamp': timestamp
		}
	
	if LevelEditor.create_new_keyframe(key, new_keyframe_data, timestamp):
		Global.undo_redo.create_action("Add Modifier")
		Global.undo_redo.add_do_method(add_keyframe.bind(new_keyframe_data))
		Global.undo_redo.add_undo_method(remove_keyframe.bind(new_keyframe_data))
		Global.undo_redo.commit_action()

func delete_keyframe(data: Dictionary):
	Console.log({"message": 'Deleting modifier at "%s"' % data['timestamp']})
	Global.undo_redo.create_action("Remove Modifier")
	Global.undo_redo.add_do_method(remove_keyframe.bind(data))
	Global.undo_redo.add_undo_method(add_keyframe.bind(data))
	Global.undo_redo.commit_action()
