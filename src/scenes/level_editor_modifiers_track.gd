extends Node2D

@export var editor_keyframe_prefab: PackedScene

func load_keyframes():
	LevelEditor.place_init_keyframes("modifiers", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func create_modifier():
	var timestamp = LevelEditor.get_timestamp()
	var prev_bpm = Config.keyframes['modifiers'].filter(func(a): return timestamp > a['timestamp']).back()
	if prev_bpm == null: prev_bpm = Config.keyframes['modifiers'][0]
	
	var new_modifier_data = {
		'bpm': prev_bpm.bpm,
		'timestamp': timestamp
		}
	
	LevelEditor.create_new_keyframe("modifiers", new_modifier_data, timestamp)
	LevelEditor.add_single_keyframe(new_modifier_data, self, editor_keyframe_prefab)
