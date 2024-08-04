extends AudioStreamPlayer
class_name LevelEditorMusic

func _ready():
	if Editor.project_loaded:
		set_editor_music()
		seek(LevelEditor.song_position_raw)

func set_editor_music():
	stop()
	
	stream = Assets.get_asset(Config.asset['song_path'])
	if stream == null: stream = preload("res://assets/audio/placeholder_song.ogg")
	
	LevelEditor.calculate_song_info(stream)

func _input(event):
	if not Editor.controls_enabled: return
	
	if event.is_action_pressed("ui_accept"):
		if playing: pause()
		else: unpause()

func pause():
	_set_playing(false)
	LevelEditor.pause_position = LevelEditor.song_position_raw

func unpause():
	_set_playing(true)
	seek(LevelEditor.pause_position)

func _process(_delta):
	if not Editor.project_loaded: return
	
	if playing:
		LevelEditor.song_position_raw = Util.get_game_audio_stream_pos(self)
	LevelEditor.song_position_offset = LevelEditor.song_position_raw - Config.settings['song_offset']
