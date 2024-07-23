extends AudioStreamPlayer

func _ready():
	EventManager.editor_note_hit.connect(_on_editor_note_hit)
	change_loop_sound(0)
	
	var tsevent = TSEvent.new()
	tsevent.callback = change_loop_sound
	tsevent.config_key = "sound_loop"
	add_child(tsevent)

func change_loop_sound(idx: int):
	if Config.keyframes.get('sound_loop', []).is_empty(): return
	var sound = Config.keyframes['sound_loop'][idx]
	stream = Assets.get_asset(sound['path'])

func _on_editor_note_hit(_data):
	if stream: play()
