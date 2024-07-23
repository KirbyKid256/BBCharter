extends Node2D

@export var editor_keyframe_prefab: PackedScene

func _ready():
	EventManager.editor_try_add_voicebank.connect(create_voice_audio)

func load_keyframes():
	LevelEditor.place_init_keyframes("voice_bank", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func create_voice_audio(keyframe_data: Dictionary):
	var timestamp = LevelEditor.get_timestamp()
	var new_sound_voice_data = {'timestamp': timestamp, 'voice_paths': keyframe_data['audio_path']}
	
	Console.log({"message": "Creating Voice Bank at %s" % timestamp})
	LevelEditor.create_new_keyframe("voice_bank", new_sound_voice_data, timestamp)
	LevelEditor.add_single_keyframe(new_sound_voice_data, self, editor_keyframe_prefab)
