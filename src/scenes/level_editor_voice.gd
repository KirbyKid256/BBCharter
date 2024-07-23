extends AudioStreamPlayer

var voice_bank: Array = Config.keyframes.get('voice_bank', [])
var current_bank_index: int
var current_bank: Array

var voice_trigger_index: int
var last_voice_trigger_index: int

func _ready():
	EventManager.editor_note_hit.connect(_on_editor_note_hit)
	change_voice_bank(0)
	
	var tsevent = TSEvent.new()
	tsevent.callback = change_voice_bank
	tsevent.config_key = "voice_bank"
	add_child(tsevent)

func _process(_delta):
	if not Editor.level_loaded: return
	
	var arr = Difficulty.get_chart_notes().filter(func(note): return LevelEditor.song_position_offset >= note['timestamp'] and note.get('trigger_voice', false))
	voice_trigger_index = arr.size()
	if voice_trigger_index != last_voice_trigger_index:
		last_voice_trigger_index = voice_trigger_index

func change_voice_bank(idx: int):
	# Check if voices exist
	if voice_bank.is_empty(): return
	
	current_bank.clear()
	for voice_file in voice_bank[idx].get('voice_paths',[]):
		current_bank.append(Assets.get_asset(voice_file))

func _on_editor_note_hit(note):
	# Trigger Voice
	if note.get('trigger_voice', false) == true and current_bank.size() > 0:
		current_bank_index = wrapi(voice_trigger_index, 0, current_bank.size())
		stream = current_bank[current_bank_index]
		play()