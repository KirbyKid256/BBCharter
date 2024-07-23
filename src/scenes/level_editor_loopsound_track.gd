extends Node2D

@export var editor_keyframe_prefab: PackedScene

func _ready():
	EventManager.editor_try_add_loopsound.connect(create_keyframe)

func load_keyframes():
	LevelEditor.place_init_keyframes("sound_loop", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func create_keyframe(keyframe_data: Dictionary):
	var timestamp = LevelEditor.get_timestamp()
	var new_loopsound_data = {'path': keyframe_data['audio_path'], 'timestamp': timestamp}

	Console.log({"message": "Creating Sound Loop at %s" % timestamp})
	LevelEditor.create_new_keyframe("sound_loop", new_loopsound_data, timestamp)
	LevelEditor.add_single_keyframe(new_loopsound_data, self, editor_keyframe_prefab)
