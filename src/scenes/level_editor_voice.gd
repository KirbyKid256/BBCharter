extends AudioStreamPlayer

var current_bank: Array

var voice_trigger_index: int
var last_voice_trigger_index: int

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	
	var tsevent = TSEvent.new()
	tsevent.callback = change_voice_bank
	tsevent.config_key = "voice_bank"
	add_child(tsevent)
	
	if Editor.project_loaded:
		current_bank.clear()
		change_voice_bank(tsevent.index)

func _on_editor_project_loaded():
	current_bank.clear()

func _process(_delta):
	if not Editor.project_loaded: return
	
	var arr = Difficulty.get_chart_notes().filter(func(note): return LevelEditor.song_position_offset >= note['timestamp'] and note.get('trigger_voice', false))
	voice_trigger_index = arr.size()
	if voice_trigger_index != last_voice_trigger_index:
		last_voice_trigger_index = voice_trigger_index

func change_voice_bank(idx: int):
	# Check if voices exist
	if Config.keyframes['voice_bank'].is_empty() or idx < 0: current_bank.clear(); return
	
	current_bank.clear()
	for voice_file in Config.keyframes['voice_bank'][idx]['voice_paths']:
		current_bank.append(Assets.get_asset(voice_file))
