extends Node2D

@export var editor_keyframe_prefab: PackedScene

func _ready():
	EventManager.editor_try_add_background.connect(create_keyframe)

func load_keyframes():
	LevelEditor.place_init_keyframes("background", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

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
	
	LevelEditor.create_new_keyframe("background", new_keyframe_data, timestamp)
	LevelEditor.add_single_keyframe(new_keyframe_data, self, editor_keyframe_prefab)
