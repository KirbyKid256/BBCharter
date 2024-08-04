extends AudioStreamPlayer

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	EventManager.editor_note_hit.connect(_on_editor_note_hit)
	
	var tsevent = TSEvent.new()
	tsevent.callback = change_loop_sound
	tsevent.config_key = "sound_loop"
	add_child(tsevent)
	
	if Editor.project_loaded: change_loop_sound(tsevent.index)

func _on_editor_project_loaded():
	stream = null

func change_loop_sound(idx: int):
	if Config.keyframes['sound_loop'].is_empty() or idx < 0: stream = null; return
	
	var sound = Config.keyframes['sound_loop'][idx]
	stream = Assets.get_asset(sound['path'])

func _on_editor_note_hit(_data):
	if stream: play()
