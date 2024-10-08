extends Node2D

@export var editor_note_prefab: PackedScene

@onready var note_selector: NoteSelector = $'../../../NoteSelector'
@onready var menu_bar: MenuBar = $'../../../MenuBar'

var note_clipboard: Array

func _ready():
	EventManager.editor_project_loaded.connect(note_selector.deselect_notes)
	if Editor.project_loaded: note_selector.deselect_notes()

func load_notes():
	for editor_note in Difficulty.get_chart_notes():
		var new_editor_note = editor_note_prefab.instantiate() as EditorNote
		add_child(new_editor_note)
		new_editor_note.setup(editor_note)

func clear_notes():
	note_selector.deselect_notes()
	if Difficulty.get_chart_notes().is_empty(): return
	
	Difficulty.get_chart_notes().clear()
	Util.clear_children_node_2d(self)

func clear_notes_oob():
	note_selector.deselect_notes()
	
	var song_length_offset = snappedf(LevelEditor.song_length - Config.settings['song_offset'], 0.001)
	var outer_notes = Difficulty.get_chart_notes().filter(func(note): return note.timestamp > song_length_offset or note.timestamp < -Config.settings['song_offset']).duplicate(true)
	
	if outer_notes.is_empty(): return
	
	Global.undo_redo.create_action("Clear Notes")
	Global.undo_redo.add_do_method(func():
		for note: Dictionary in outer_notes: remove_note(note))
	Global.undo_redo.add_undo_method(func():
		for note: Dictionary in outer_notes: add_note(note))
	Global.undo_redo.commit_action()

func _input(event):
	if not Editor.project_loaded: return
	if not Editor.controls_enabled: return
	
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
	menu_bar.edit_popup_menu.set_item_disabled(5, false)

func copy_selected_notes():
	if LevelEditor.selected_notes.is_empty(): Console.log({"message": "No Notes to copy..."}); return
	note_clipboard.clear()
	for note: EditorNote in LevelEditor.selected_notes:
		note_clipboard.append(note.data)
	menu_bar.edit_popup_menu.set_item_disabled(5, false)
 
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
		var selected_data: Array
		var old_input_types: Array; var new_input_types: Array
		var change_notes: bool
		
		for note in LevelEditor.selected_notes:
			if note.data.input_type != input_type: change_notes = true
			selected_data.append(note.data)
			old_input_types.append(note.data.input_type)
			new_input_types.append(input_type)
		
		if not change_notes: return
		
		Global.undo_redo.create_action("Change Notes")
		Global.undo_redo.add_do_method(func():
			for i in selected_data.size():
				var note: EditorNote = get_child(Difficulty.get_chart_notes().find(selected_data[i]))
				note.data.input_type = new_input_types[i]
				note.update_visual())
		Global.undo_redo.add_undo_method(func():
			for i in selected_data.size():
				var note: EditorNote = get_child(Difficulty.get_chart_notes().find(selected_data[i]))
				note.data.input_type = old_input_types[i]
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
	copied_note_data.timestamp = note.timestamp + LevelEditor.get_timestamp() - note_clipboard[0].timestamp 
	
	# Check if note already exists there
	if not Difficulty.get_chart_notes().filter(check_note_exists.bind(copied_note_data.timestamp)).is_empty():
		Console.log({"message": "Note already exists..."}); return {}
	
	# Offset hold notes
	if copied_note_data.note_modifier == LevelEditor.NOTETYPE.HOLD:
		var hold_time = note.hold_end_timestamp - note.timestamp 
		copied_note_data.hold_end_timestamp = copied_note_data.timestamp + hold_time
	
	return copied_note_data

func check_note_exists(note, new_note_timestamp):
	return snappedf(note.timestamp, 0.001) == snappedf(new_note_timestamp, 0.001)

func add_note(data: Dictionary):
	Difficulty.get_chart_notes().append(data)
	Difficulty.get_chart_notes().sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	note_selector.deselect_notes()
	
	var note = editor_note_prefab.instantiate() as EditorNote
	add_child(note); note.setup(data)

func remove_note(data: Dictionary):
	var idx = Difficulty.get_chart_notes().find(data)
	Difficulty.get_chart_notes().remove_at(idx)
	note_selector.deselect_notes()
	Util.free_node(get_child(idx))

func move_note(data: Dictionary, time: float):
	var old_time: float = data.timestamp
	var old_times: Array; var new_times: Array
	var selected_data: Array
	
	var do_move = func(d, t):
		var note = get_child(Difficulty.get_chart_notes().find(d))
		
		var difference = note.data.get('hold_end_timestamp', note.data.timestamp) - note.data.timestamp
		if note.data.has('hold_end_timestamp'): note.data.hold_end_timestamp = t + difference
		note.data.timestamp = t
		
		note.update_position()
		note.input_handler.tooltip_text = str(note.data).replace(", ", "\r\n")\
		.replace("{", "").replace("}", "").replace("\"", "")
	
	for note in LevelEditor.selected_notes:
		selected_data.append(note.data)
		old_times.append(note.data.timestamp)
		new_times.append(note.mouse_drag_time)
	
	Global.undo_redo.create_action("Move Note")
	Global.undo_redo.add_do_method(func():
		if selected_data.has(data):
			for i in selected_data.size():
				do_move.call(selected_data[i], new_times[i])
		else:
			do_move.call(data, time))
	Global.undo_redo.add_undo_method(func():
		if selected_data.has(data):
			for i in selected_data.size():
				do_move.call(selected_data[i], old_times[i])
		else:
			do_move.call(data, old_time))
	Global.undo_redo.commit_action()

func modify_note(data: Dictionary, modifier: int):
	var selected_data: Array
	for note in LevelEditor.selected_notes:
		selected_data.append(note.data)
	
	if selected_data.has(data):
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
	
	if selected_data.has(data):
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
