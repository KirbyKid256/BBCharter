extends AudioStreamPlayer
class_name LevelEditorMusic

func set_editor_music(sync: bool = true):
	stop()
	
	stream = Assets.get_asset(Config.asset['song_path'])
	if stream == null: stream = preload("res://assets/audio/placeholder_song.ogg")
	
	LevelEditor.calculate_song_info(stream)

func _input(event):
	if not LevelEditor.controls_enabled: return
	
	# Zooming
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
	if not Editor.level_loaded: return
	
	if playing:
		LevelEditor.song_position_raw = Util.get_game_audio_stream_pos(self)
	LevelEditor.song_position_offset = LevelEditor.song_position_raw - Config.settings['song_offset']
