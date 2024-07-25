extends Node2D

@export var editor_keyframe_prefab: PackedScene

func _ready():
	EventManager.editor_try_add_effect.connect(create_keyframe)

func load_keyframes():
	LevelEditor.place_init_keyframes("effects", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func create_keyframe(keyframe_data: Dictionary):
	var timestamp = LevelEditor.get_timestamp()
	var new_keyframe_data: Dictionary = {
		"duration": keyframe_data["duration"],
		"path": keyframe_data["sprite_sheet"],
		"sheet_data": keyframe_data["sheet_data"],
		"timestamp": timestamp
	}
	
	if LevelEditor.create_new_keyframe("effects", new_keyframe_data, timestamp):
		LevelEditor.add_single_keyframe(new_keyframe_data, self, editor_keyframe_prefab)
		Editor.project_changed = true
