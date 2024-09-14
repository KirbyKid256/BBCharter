extends Node2D

@export var editor_keyframe_prefab: PackedScene

func _ready():
	EventManager.editor_try_add_effect.connect(create_keyframe)
	if Editor.project_loaded: load_keyframes()

func load_keyframes():
	LevelEditor.place_init_keyframes("effects", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func _update_child_order():
	for child in get_children():
		var idx: int = Config.keyframes['effects'].find(child.data)
		if child.get_index() != idx: move_child(child, idx)

func _add_effect(data: Dictionary):
	LevelEditor.add_single_keyframe(data, self, editor_keyframe_prefab)
	if Config.keyframes['effects'].find(data) < 0:
		Config.keyframes['effects'].append(data)
		Config.keyframes['effects'].sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	
	_update_child_order()

func _remove_effect(data: Dictionary):
	_update_child_order()
	
	var idx: int = Config.keyframes['effects'].find(data)
	Util.free_node(get_child(idx))
	Config.keyframes['effects'].remove_at(idx)

func create_keyframe(keyframe_data: Dictionary):
	var timestamp = LevelEditor.get_timestamp()
	var new_keyframe_data: Dictionary = {
		"duration": keyframe_data["duration"],
		"path": keyframe_data["sprite_sheet"],
		"sheet_data": keyframe_data["sheet_data"],
		"timestamp": timestamp
	}
	
	if LevelEditor.create_new_keyframe("effects", new_keyframe_data, timestamp):
		Global.undo_redo.create_action("Add Effect")
		Global.undo_redo.add_do_method(_add_effect.bind(new_keyframe_data))
		Global.undo_redo.add_undo_method(_remove_effect.bind(new_keyframe_data))
		Global.undo_redo.commit_action()
		Editor.level_changed = true

func remove_keyframe(data: Dictionary):
	Console.log({"message": 'Deleting effect at "%s"' % data['timestamp']})
	Global.undo_redo.create_action("Remove Effect")
	Global.undo_redo.add_do_method(_remove_effect.bind(data))
	Global.undo_redo.add_undo_method(_add_effect.bind(data))
	Global.undo_redo.commit_action()
	Editor.level_changed = true
