extends Node2D

@export var editor_shutter_prefab: PackedScene

func _ready():
	if Editor.project_loaded: load_keyframes()

func load_keyframes():
	LevelEditor.place_init_keyframes("shutter", self, editor_shutter_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func _update_child_order():
	for child in get_children():
		var idx: int = Config.keyframes['shutter'].find(child.data)
		if child.get_index() != idx: move_child(child, idx)

func _add_shutter(data: Dictionary):
	LevelEditor.add_single_keyframe(data, self, editor_shutter_prefab)
	if Config.keyframes['shutter'].find(data) < 0:
		Config.keyframes['shutter'].append(data)
		Config.keyframes['shutter'].sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	
	_update_child_order()

func _remove_shutter(data: Dictionary):
	_update_child_order()
	
	var idx: int = Config.keyframes['shutter'].find(data)
	Util.free_node(get_child(idx))
	Config.keyframes['shutter'].remove_at(idx)

func create_keyframe():
	var timestamp = LevelEditor.get_timestamp()
	var new_keyframe_data = {'timestamp': timestamp}
	
	if LevelEditor.create_new_keyframe("shutter", new_keyframe_data, timestamp):
		Global.undo_redo.create_action("Add Shutter")
		Global.undo_redo.add_do_method(_add_shutter.bind(new_keyframe_data))
		Global.undo_redo.add_undo_method(_remove_shutter.bind(new_keyframe_data))
		Global.undo_redo.commit_action()

func remove_keyframe(data: Dictionary):
	Console.log({"message": 'Deleting shutter at "%s"' % data['timestamp']})
	Global.undo_redo.create_action("Remove Shutter")
	Global.undo_redo.add_do_method(_remove_shutter.bind(data))
	Global.undo_redo.add_undo_method(_add_shutter.bind(data))
	Global.undo_redo.commit_action()
