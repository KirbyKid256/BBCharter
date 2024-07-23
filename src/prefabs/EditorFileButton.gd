extends Button

@onready var file_drop: Control = $"../../../../../FileDrop"

func _on_button_up():
	file_drop.pending_audio_data['audio_path'].append(text)
	
	var asset = file_drop.voice_asset.instantiate() as Control
	file_drop.create_audio_voice_paths.add_child(asset)
	asset.setup(text)
