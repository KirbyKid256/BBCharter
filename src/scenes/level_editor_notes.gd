extends Node2D

@export var editor_note_prefab: PackedScene
@onready var note_selector: NoteSelector = $'../../../NoteSelector'

var note_clipboard: Array

func _ready():
	EventManager.editor_note_created.connect(_on_editor_note_created)

func load_notes():
	for editor_note in Difficulty.get_chart_notes():
		var new_editor_note = editor_note_prefab.instantiate() as EditorNote
		add_child(new_editor_note)
		new_editor_note.setup(editor_note)

func _input(event):
	if not Editor.level_loaded: return
	
	if MenuCache.menu_disabled(self): return
	if not LevelEditor.controls_enabled: return
	
	if event.is_action_pressed("ui_cut"): cut_selected_notes()
	if event.is_action_pressed("ui_copy"): copy_selected_notes()
	if event.is_action_pressed("ui_paste"): paste_selected_notes()
	
	if event is InputEventKey and event.alt_pressed: return
	if event is InputEventKey and event.is_command_or_control_pressed(): return
	
	if event.is_action_pressed("action_0"): create_note(0)
	if event.is_action_pressed("action_1"): create_note(1)
	if event.is_action_pressed("action_2"): create_note(2)
	if event.is_action_pressed("action_3"): create_note(3)

func cut_selected_notes():
	if LevelEditor.selected_notes.is_empty(): Console.log({"message": "No Notes to cut..."}); return
	note_clipboard.clear()
	for note: EditorNote in LevelEditor.selected_notes:
		note_clipboard.append(note.data)
	note_selector.group_delete_notes()

func copy_selected_notes():
	if LevelEditor.selected_notes.is_empty(): Console.log({"message": "No Notes to copy..."}); return
	note_clipboard.clear()
	for note: EditorNote in LevelEditor.selected_notes:
		note_clipboard.append(note.data)
 
func paste_selected_notes():
	if note_clipboard.is_empty(): Console.log({"message": "No Notes to paste..."}); return
	for note: Dictionary in note_clipboard:
		copy_note(note)

func create_note(input_type: int = 0):
	# Batch Replace Note Types
	if LevelEditor.selected_notes.size() >= 1:
		for note: EditorNote in LevelEditor.selected_notes: 
			if note == null: return
			note.data['input_type'] = input_type
			note.update_visual()
		return
	
	var new_note_timestamp = LevelEditor.get_timestamp()
	
	# Check if note already exists there
	if not Difficulty.get_chart_notes().filter(check_note_exists.bind(new_note_timestamp)).is_empty():
		Console.log({"message": "Note already exists..."}); return
	
	var new_note_data = {'input_type':input_type, "note_modifier":0, 'timestamp':new_note_timestamp}
	Difficulty.get_chart_notes().append(new_note_data)
	Difficulty.get_chart_notes().sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	EventManager.emit_signal("editor_note_created", new_note_data)

func copy_note(note: Dictionary):
	var copied_note_data = note.duplicate(true)
	
	# Get first notes offset
	copied_note_data['timestamp'] = note['timestamp']\
	+ LevelEditor.get_timestamp() - note_clipboard[0]['timestamp'] 
	
	# Offset hold notes
	if copied_note_data['note_modifier'] == LevelEditor.NOTETYPE.HOLD:
		var hold_time = note['hold_end_timestamp'] - note['timestamp'] 
		copied_note_data['hold_end_timestamp'] = copied_note_data['timestamp'] + hold_time
	
	# Check if note already exists there
	if not Difficulty.get_chart_notes().filter(check_note_exists.bind(copied_note_data['timestamp'])).is_empty():
		Console.log({"message": "Note already exists..."}); return
	
	Difficulty.get_chart_notes().append(copied_note_data)
	Difficulty.get_chart_notes().sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	EventManager.editor_note_created.emit(copied_note_data)

func check_note_exists(note, new_note_timestamp):
	var snapped_note_check = Math.beat_to_secs_dynamic(snappedf(Math.secs_to_beat_dynamic(note['timestamp']), 1.0 / LevelEditor.snapping_factor)
	if LevelEditor.snapping_allowed else Math.secs_to_beat_dynamic(note['timestamp']))
	return snapped_note_check == new_note_timestamp

func _on_editor_note_created(new_editor_note_data: Dictionary):
	var new_editor_note = editor_note_prefab.instantiate() as Node2D
	add_child(new_editor_note)
	new_editor_note.setup(new_editor_note_data)
