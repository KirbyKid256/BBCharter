extends Node2D

@export var key: String
@export var prefab: PackedScene

@onready var background = $"../../../../Preview/Background"

func _ready():
	EventManager.editor_try_add_background.connect(create_keyframe)
	if Editor.project_loaded: load_keyframes()

func load_keyframes():
	LevelEditor.place_init_keyframes(key, self, prefab)

func clear_keyframes():
	for i in range(get_child_count()-1, -1, -1):
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
	
	if LevelEditor.song_position_offset > data['timestamp']:
		background.change_background(Config.keyframes['background'].find(data))
	
	_update_child_order()

func remove_keyframe(data: Dictionary):
	_update_child_order()
	
	var idx: int = Config.keyframes[key].find(data)
	Util.free_node(get_child(idx))
	Config.keyframes[key].remove_at(idx)
	
	if Config.keyframes[key].is_empty() or LevelEditor.song_position_offset > data['timestamp']:
		background.change_background(clampi(idx, 0, Config.keyframes[key].size() - 1))

func create_keyframe(keyframe_data: Dictionary):
	var timestamp = LevelEditor.get_timestamp()
	var new_keyframe_data: Dictionary = {
		"path": keyframe_data["sprite_sheet"],
		"timestamp": timestamp
	}
	
	if keyframe_data.has("expand_mode"):
		new_keyframe_data.merge ({"expand_mode": keyframe_data["expand_mode"]})
	if keyframe_data.has("stretch_mode"):
		new_keyframe_data.merge ({"stretch_mode": keyframe_data["stretch_mode"]})
	
	if LevelEditor.create_new_keyframe(key, new_keyframe_data, timestamp):
		Global.undo_redo.create_action("Add Background")
		Global.undo_redo.add_do_method(add_keyframe.bind(new_keyframe_data))
		Global.undo_redo.add_undo_method(remove_keyframe.bind(new_keyframe_data))
		Global.undo_redo.commit_action()

func delete_keyframe(data: Dictionary):
	Console.log({"message": 'Deleting background at "%s"' % data['timestamp']})
	Global.undo_redo.create_action("Remove Background")
	Global.undo_redo.add_do_method(remove_keyframe.bind(data))
	Global.undo_redo.add_undo_method(add_keyframe.bind(data))
	Global.undo_redo.commit_action()
