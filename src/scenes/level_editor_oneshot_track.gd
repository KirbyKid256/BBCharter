extends Node2D

@export var editor_keyframe_prefab: PackedScene

func _ready():
	EventManager.editor_try_add_oneshot.connect(create_oneshot_audio)

func load_keyframes():
	LevelEditor.place_init_keyframes("sound_oneshot", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func create_oneshot_audio(keyframe_data: Dictionary):
	var timestamp = LevelEditor.get_timestamp()
	var new_sound_oneshot_data = {'path': keyframe_data['audio_path'], 'timestamp': timestamp}
	
	Console.log({"message": "Creating Oneshot Audio at %s" % timestamp})
	LevelEditor.create_new_keyframe("sound_oneshot", new_sound_oneshot_data, timestamp)
	LevelEditor.add_single_keyframe(new_sound_oneshot_data, self, editor_keyframe_prefab)
