extends Node2D

@export var editor_keyframe_prefab: PackedScene

func _ready():
	EventManager.editor_try_add_oneshot.connect(create_keyframe)
	if Editor.project_loaded: load_keyframes()

func load_keyframes():
	LevelEditor.place_init_keyframes("sound_oneshot", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func _update_child_order():
	for child in get_children():
		var idx: int = Config.keyframes['sound_oneshot'].find(child.data)
		if child.get_index() != idx: move_child(child, idx)

func _add_oneshot(data: Dictionary):
	LevelEditor.add_single_keyframe(data, self, editor_keyframe_prefab)
	if Config.keyframes['sound_oneshot'].find(data) < 0:
		Config.keyframes['sound_oneshot'].append(data)
		Config.keyframes['sound_oneshot'].sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	
	_update_child_order()

func _remove_oneshot(data: Dictionary):
	_update_child_order()
	
	var idx: int = Config.keyframes['sound_oneshot'].find(data)
	Util.free_node(get_child(idx))
	Config.keyframes['sound_oneshot'].remove_at(idx)

func create_keyframe(keyframe_data: Dictionary):
	var timestamp = LevelEditor.get_timestamp()
	var new_keyframe_data = {'path': keyframe_data['audio_path'], 'timestamp': timestamp}
	
	if LevelEditor.create_new_keyframe("sound_oneshot", new_keyframe_data, timestamp):
		Global.undo_redo.create_action("Add Oneshot")
		Global.undo_redo.add_do_method(_add_oneshot.bind(new_keyframe_data))
		Global.undo_redo.add_undo_method(_remove_oneshot.bind(new_keyframe_data))
		Global.undo_redo.commit_action()
		Editor.level_changed = true

func remove_keyframe(data: Dictionary):
	Console.log({"message": 'Deleting oneshot at "%s"' % data['timestamp']})
	Global.undo_redo.create_action("Remove Oneshot")
	Global.undo_redo.add_do_method(_remove_oneshot.bind(data))
	Global.undo_redo.add_undo_method(_add_oneshot.bind(data))
	Global.undo_redo.commit_action()
	Editor.level_changed = true
