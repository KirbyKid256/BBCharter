extends Node2D

@export var editor_keyframe_prefab: PackedScene

func _ready():
	if Editor.project_loaded: load_keyframes()

func load_keyframes():
	LevelEditor.place_init_keyframes("modifiers", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func _update_child_order():
	for child in get_children():
		var idx: int = Config.keyframes['modifiers'].find(child.data)
		if child.get_index() != idx: move_child(child, idx)

func _add_modifier(data: Dictionary):
	LevelEditor.add_single_keyframe(data, self, editor_keyframe_prefab)
	if Config.keyframes['modifiers'].find(data) < 0:
		Config.keyframes['modifiers'].append(data)
		Config.keyframes['modifiers'].sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	
	_update_child_order()

func _remove_modifier(data: Dictionary):
	_update_child_order()
	
	var idx: int = Config.keyframes['modifiers'].find(data)
	Util.free_node(get_child(idx))
	Config.keyframes['modifiers'].remove_at(idx)

func create_keyframe():
	var timestamp = LevelEditor.get_timestamp()
	timestamp = clampf(timestamp, 0, timestamp)
	
	var prev_bpm = Config.keyframes['modifiers'].filter(func(a): return timestamp > a['timestamp']).back()
	if prev_bpm == null: prev_bpm = Config.keyframes['modifiers'][0]
	
	var new_keyframe_data = {
		'bpm': prev_bpm.bpm,
		'timestamp': timestamp
		}
	
	if LevelEditor.create_new_keyframe("modifiers", new_keyframe_data, timestamp):
		Global.undo_redo.create_action("Add Modifier")
		Global.undo_redo.add_do_method(_add_modifier.bind(new_keyframe_data))
		Global.undo_redo.add_undo_method(_remove_modifier.bind(new_keyframe_data))
		Global.undo_redo.commit_action()

func remove_keyframe(data: Dictionary):
	Console.log({"message": 'Deleting modifier at "%s"' % data['timestamp']})
	Global.undo_redo.create_action("Remove Modifier")
	Global.undo_redo.add_do_method(_remove_modifier.bind(data))
	Global.undo_redo.add_undo_method(_add_modifier.bind(data))
	Global.undo_redo.commit_action()
