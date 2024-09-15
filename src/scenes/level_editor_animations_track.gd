extends Node2D

@export var key: String
@export var prefab: PackedScene

@onready var character = $"../../../../Preview/Character"

func _ready():
	EventManager.editor_try_add_animation.connect(create_keyframe)
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
	
	if Config.keyframes[key].is_empty() or LevelEditor.song_position_offset > data['timestamp']:
		character.change_animation(Config.keyframes[key].find(data))
	elif LevelEditor.song_position_offset <= Config.keyframes[key][0].timestamp:
		character.change_animation(0)
	
	_update_child_order()

func remove_keyframe(data: Dictionary):
	_update_child_order()
	
	var idx: int = Config.keyframes[key].find(data)
	Util.free_node(get_child(idx))
	Config.keyframes[key].remove_at(idx)
	
	if Config.keyframes[key].is_empty() or LevelEditor.song_position_offset > data['timestamp']:
		character.change_animation(clampi(idx, 0, Config.keyframes[key].size() - 1))
	elif LevelEditor.song_position_offset <= Config.keyframes[key][0].timestamp:
		character.change_animation(0)

func create_keyframe(keyframe_data: Dictionary):
	var timestamp = LevelEditor.get_timestamp()
	var new_keyframe_data: Dictionary = {
		"animations": {"normal": keyframe_data["sprite_sheet"]},
		"sheet_data": keyframe_data["sheet_data"],
		"timestamp": timestamp
	}
	
	if keyframe_data.has("scale_multiplier"):
		new_keyframe_data.merge({"scale_multiplier": keyframe_data["scale_multiplier"]})
	
	if LevelEditor.create_new_keyframe(key, new_keyframe_data, timestamp):
		Global.undo_redo.create_action("Add Animation")
		Global.undo_redo.add_do_method(add_keyframe.bind(new_keyframe_data))
		Global.undo_redo.add_undo_method(remove_keyframe.bind(new_keyframe_data))
		Global.undo_redo.commit_action()

func delete_keyframe(data: Dictionary):
	Console.log({"message": 'Deleting animation at "%s"' % data['timestamp']})
	Global.undo_redo.create_action("Remove Animation")
	Global.undo_redo.add_do_method(remove_keyframe.bind(data))
	Global.undo_redo.add_undo_method(add_keyframe.bind(data))
	Global.undo_redo.commit_action()
