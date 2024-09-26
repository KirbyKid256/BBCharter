extends VideoStreamPlayer

@onready var audio: AudioStreamPlayer = $Audio

func preview(path: String = "", add_audio: bool = true):
	if not Editor.project_loaded: return
	
	if is_playing():
		stop()
		audio.stop()
	
	stream = Assets.get_asset(path if not path.is_empty() else Config.asset.get("final_video", ""))
	if add_audio: audio.stream = Assets.get_asset(Config.asset.get("final_audio", ""))
	
	if stream != null:
		play()
		if add_audio: audio.play()
		show()

func get_thumbnail(path: String = "") -> Texture2D:
	if is_playing(): return
	
	var thumbnail: Texture2D = null
	stream = Assets.get_asset(path if not path.is_empty() else Config.asset.get("final_video", ""))
	
	if stream != null:
		hide(); play()
		thumbnail = get_video_texture().duplicate()
		stop(); show()
	
	return thumbnail

func _on_finished():
	audio.stop()
