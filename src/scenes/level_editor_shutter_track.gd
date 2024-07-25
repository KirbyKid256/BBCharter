extends Node2D

@export var editor_shutter_prefab: PackedScene

func load_keyframes():
	LevelEditor.place_init_keyframes("shutter", self, editor_shutter_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func create_keyframe():
	var timestamp = LevelEditor.get_timestamp()
	var new_keyframe_data = {'timestamp': timestamp}
	
	if LevelEditor.create_new_keyframe("shutter", new_keyframe_data, timestamp):
		LevelEditor.add_single_keyframe(new_keyframe_data, self, editor_shutter_prefab)
		Editor.project_changed = true
