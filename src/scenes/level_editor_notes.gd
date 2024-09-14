extends Node2D

@export var editor_note_prefab: PackedScene
@onready var note_selector: NoteSelector = $'../../../NoteSelector'

var note_clipboard: Array

func _ready():
	if Editor.project_loaded: load_notes()

func load_notes():
	LevelEditor.selected_notes.clear()
	for editor_note in Difficulty.get_chart_notes():
		var new_editor_note = editor_note_prefab.instantiate() as EditorNote
		add_child(new_editor_note)
		new_editor_note.setup(editor_note)

func _input(event):
	if not Editor.project_loaded: return
	if not Editor.controls_enabled: return
	
	if event.is_action_pressed("ui_cut"): cut_selected_notes()
	if event.is_action_pressed("ui_copy"): copy_selected_notes()
	if event.is_action_pressed("ui_paste"): paste_selected_notes()
	
	if event is InputEventKey and event.alt_pressed: return
	if event is InputEventKey and event.is_command_or_control_pressed(): return
	
	for i in 4:
		if event.is_action_pressed("action_" + str(i)): create_note(i)

func cut_selected_notes():
	if LevelEditor.selected_notes.is_empty(): Console.log({"message": "No Notes to cut..."}); return
	note_clipboard.clear()
	for note: EditorNote in LevelEditor.selected_notes:
		note_clipboard.append(note.data)
	note_selector.group_remove_notes()

func copy_selected_notes():
	if LevelEditor.selected_notes.is_empty(): Console.log({"message": "No Notes to copy..."}); return
	note_clipboard.clear()
	for note: EditorNote in LevelEditor.selected_notes:
		note_clipboard.append(note.data)
 
func paste_selected_notes():
	if note_clipboard.is_empty(): Console.log({"message": "No Notes to paste..."}); return
	
	var paste_notes: Array
	for note: Dictionary in note_clipboard:
		var copied_note = copy_note(note)
		if copied_note.is_empty(): return
		paste_notes.append(copied_note)
	
	Global.undo_redo.create_action("Paste Notes")
	Global.undo_redo.add_do_method(func():
		for note: Dictionary in paste_notes: add_note(note))
	Global.undo_redo.add_undo_method(func():
		for note: Dictionary in paste_notes: remove_note(note))
	Global.undo_redo.commit_action()

func create_note(input_type: int = 0):
	# Batch Replace Note Types
	if LevelEditor.selected_notes.size() > 0:
		var selected_notes: Array; var selected_data: Array
		for note: EditorNote in LevelEditor.selected_notes:
			selected_notes.append(note)
			selected_data.append(note.data.duplicate(true))
		
		Global.undo_redo.create_action("Change Notes")
		Global.undo_redo.add_do_method(func():
			for i in selected_notes.size():
				if selected_notes[i] == null:
					selected_notes[i] = get_child(Difficulty.get_chart_notes().find(selected_data[i]))
					selected_data[i] = selected_notes[i].data
				
				var note: EditorNote = selected_notes[i]
				if note == null: continue
				note.data['input_type'] = input_type
				note.update_visual())
		Global.undo_redo.add_undo_method(func():
			for i in selected_notes.size():
				if selected_notes[i] == null:
					selected_notes[i] = get_child(Difficulty.get_chart_notes().find(selected_data[i]))
					selected_data[i] = selected_notes[i].data
				
				var note: EditorNote = selected_notes[i]
				if note == null: continue
				note.data['input_type'] = selected_data[i].input_type
				note.update_visual())
		Global.undo_redo.commit_action()
		
		return
	
	var new_note_timestamp = LevelEditor.get_timestamp()
	
	# Check if note already exists there
	if not Difficulty.get_chart_notes().filter(check_note_exists.bind(new_note_timestamp)).is_empty():
		Console.log({"message": "Note already exists..."}); return
	
	var new_note_data = {'input_type':input_type, "note_modifier":0, 'timestamp':new_note_timestamp}
	Global.undo_redo.create_action("Add Note")
	Global.undo_redo.add_do_method(add_note.bind(new_note_data))
	Global.undo_redo.add_undo_method(remove_note.bind(new_note_data))
	Global.undo_redo.commit_action()

func copy_note(note: Dictionary) -> Dictionary:
	var copied_note_data = note.duplicate(true)
	
	# Get first notes offset
	copied_note_data['timestamp'] = note['timestamp'] + LevelEditor.get_timestamp() - note_clipboard[0]['timestamp'] 
	
	# Check if note already exists there
	if not Difficulty.get_chart_notes().filter(check_note_exists.bind(copied_note_data['timestamp'])).is_empty():
		Console.log({"message": "Note already exists..."}); return {}
	
	# Offset hold notes
	if copied_note_data['note_modifier'] == LevelEditor.NOTETYPE.HOLD:
		var hold_time = note['hold_end_timestamp'] - note['timestamp'] 
		copied_note_data['hold_end_timestamp'] = copied_note_data['timestamp'] + hold_time
	
	return copied_note_data

func check_note_exists(note, new_note_timestamp):
	var snapped_note_check = Math.beat_to_secs_dynamic((snappedf(Math.secs_to_beat_dynamic(note['timestamp']), 1.0 / LevelEditor.snapping_factor)
	if LevelEditor.snapping_allowed else Math.secs_to_beat_dynamic(note['timestamp'])))
	return snappedf(snapped_note_check, 0.001) == new_note_timestamp

func add_note(data: Dictionary):
	Difficulty.get_chart_notes().append(data)
	Difficulty.get_chart_notes().sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	note_selector.deselect_notes()
	
	var note = editor_note_prefab.instantiate() as EditorNote
	add_child(note); note.setup(data)
	Editor.level_changed = true

func remove_note(data: Dictionary):
	var idx = Difficulty.get_chart_notes().find(data)
	Difficulty.get_chart_notes().remove_at(idx)
	note_selector.deselect_notes()
	Util.free_node(get_child(idx))
	Editor.level_changed = true

func move_note(data: Dictionary, time: float):
	var old_time: float = data.timestamp
	var old_times: Array; var new_times: Array
	var selected_data: Array
	
	var do_move = func(d, t):
		var note = get_child(Difficulty.get_chart_notes().find(d))
		
		var difference = note.data.get('hold_end_timestamp', note.data['timestamp']) - note.data['timestamp']
		if note.data.has('hold_end_timestamp'): note.data['hold_end_timestamp'] = t + difference
		note.data['timestamp'] = t
		
		note.update_position()
		note.input_handler.tooltip_text = str(note.data).replace(", ", "\r\n")\
		.replace("{", "").replace("}", "").replace("\"", "")
	
	for note in LevelEditor.selected_notes:
		selected_data.append(note.data)
		old_times.append(note.data.timestamp)
		new_times.append(note.mouse_drag_time)
	
	Global.undo_redo.create_action("Move Note")
	Global.undo_redo.add_do_method(func():
		if selected_data.size() > 0:
			for i in selected_data.size():
				do_move.call(selected_data[i], new_times[i])
		else:
			do_move.call(data, time))
	Global.undo_redo.add_undo_method(func():
		if selected_data.size() > 0:
			for i in selected_data.size():
				do_move.call(selected_data[i], old_times[i])
		else:
			do_move.call(data, old_time))
	Global.undo_redo.commit_action()
	
	Editor.level_changed = true

func modify_note(data: Dictionary, modifier: int):
	var selected_data: Array
	for note in LevelEditor.selected_notes:
		selected_data.append(note.data)
	
	if selected_data.size() > 0:
		Global.undo_redo.create_action("Modify Notes")
		Global.undo_redo.add_do_method(func():
			for note in selected_data:
				get_child(Difficulty.get_chart_notes().find(note)).set_note_type(modifier))
		Global.undo_redo.add_undo_method(func():
			for note in selected_data:
				get_child(Difficulty.get_chart_notes().find(note)).set_note_type(note.duplicate(true).note_modifier))
		Global.undo_redo.commit_action()
	else:
		get_child(Difficulty.get_chart_notes().find(data)).set_note_type(modifier)

func voice_note(data: Dictionary):
	var selected_data: Array
	for note in LevelEditor.selected_notes:
		selected_data.append(note.data)
	
	var trigger_voice = func(note: Dictionary):
		if note.has('trigger_voice'):
			note.erase('trigger_voice')
		else:
			note['trigger_voice'] = true
		get_child(Difficulty.get_chart_notes().find(note)).update_visual()
	
	if selected_data.size() > 0:
		Global.undo_redo.create_action("Voice Notes")
		Global.undo_redo.add_do_method(func():
			for note in selected_data:
				trigger_voice.call(note))
		Global.undo_redo.add_undo_method(func():
			for note in selected_data:
				trigger_voice.call(note))
		Global.undo_redo.commit_action()
	else:
		trigger_voice.call(data)

func hold_note(data: Dictionary, time: float):
	if data['note_modifier'] == LevelEditor.NOTETYPE.NORMAL or data['note_modifier'] == LevelEditor.NOTETYPE.HOLD:
		if data['timestamp'] < time:
			data['note_modifier'] = LevelEditor.NOTETYPE.HOLD 
			data['hold_end_timestamp'] = time
		else:
			data['note_modifier'] = LevelEditor.NOTETYPE.NORMAL
			data.erase('hold_end_timestamp')
	
	var note: EditorNote = get_child(Difficulty.get_chart_notes().find(data))
	note.update_visual()
	note.update_position()
