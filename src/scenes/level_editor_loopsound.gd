extends AudioStreamPlayer

@onready var tsevent = TSEvent.new()

var current_bank: Array
var loop_trigger_index: int

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	EventManager.editor_note_hit.connect(_on_editor_note_hit)
	
	tsevent.callback = change_loop_sound
	tsevent.config_key = "sound_loop"
	add_child(tsevent)
	
	if Editor.project_loaded: change_loop_sound(tsevent.index)

func _on_editor_project_loaded():
	current_bank.clear()

func change_loop_sound(idx: int):
	current_bank.clear()
	if Config.keyframes.sound_loop.is_empty() or idx < 0: return
	
	var arr = Difficulty.get_chart_notes().filter(func(note): return LevelEditor.song_position_offset >= note.timestamp and note.timestamp >= Config.keyframes.sound_loop[idx].timestamp)
	loop_trigger_index = arr.size()-1
	
	var sound = Config.keyframes.sound_loop[idx].get('path', "")
	if typeof(sound) != TYPE_ARRAY:
		current_bank.append(Assets.get_asset(sound))
	else: for path in sound:
		current_bank.append(Assets.get_asset(path))

func _on_editor_note_hit(data):
	if current_bank.size() > 0 and data.note_modifier != LevelEditor.NOTETYPE.GHOST:
		var current_bank_index = wrapi(loop_trigger_index, 0, current_bank.size())
		stream = current_bank[current_bank_index]
		play()
