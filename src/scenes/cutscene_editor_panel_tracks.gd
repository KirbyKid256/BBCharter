extends Node

func _ready():
	EventManager.cutscene_panel_changed.connect(_on_cutscene_panel_changed)

func _on_cutscene_panel_changed():
	for stream in get_children():
		stream.stop()
		Util.free_node(stream)
	
	for track in CutsceneEditor.get_current_panel().get('audio', []):
		if not track is Dictionary: return
		# Create new stream player for each track
		var new_audio_player = AudioStreamPlayer.new()
		new_audio_player.stream = Cutscene.get_audio(track)
		add_child(new_audio_player)
		new_audio_player.play()
