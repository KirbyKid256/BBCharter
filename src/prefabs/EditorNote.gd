extends Node2D
class_name EditorNote

enum {DELETE,GHOST,AUTO,BOMB,VOICE,HOLD}

@onready var note_track: Node2D = $".."
@onready var note_selector: NoteSelector = $"../../../../NoteSelector"

@onready var note_body: Sprite2D = $NoteBody
@onready var input_handler = $InputHandler
@onready var voice_icon = $Voice
@onready var selected_visual: Sprite2D = $SelectedVisual
@onready var context_menu: PopupMenu = $ContextMenu
@onready var note_tail: Line2D = $NoteTail
@onready var tail_input_handler = $TailInputHandler
@onready var note_body_bomb: Sprite2D = $NoteBodyBomb

var hit: bool
var data: Dictionary
var selected: bool
var last_type: int

var mouse_drag: bool
var mouse_drag_time: float

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(update_position)

func setup(editor_note_data):
	data = editor_note_data
	mouse_drag_time = data['timestamp']
	update_visual()
	update_position()

func update_position():
	var hold_end_timestamp = data.get('hold_end_timestamp', data['timestamp']) - data['timestamp']
	note_tail.points[1].x = -(hold_end_timestamp * LevelEditor.note_speed_mod)
	
	if mouse_drag:
		position.x = -(mouse_drag_time * LevelEditor.note_speed_mod)
		note_tail.points[1].x = -(hold_end_timestamp * LevelEditor.note_speed_mod)
	else:
		position.x = -(data['timestamp'] * LevelEditor.note_speed_mod)
		note_tail.points[1].x = -(hold_end_timestamp * LevelEditor.note_speed_mod)
	
	tail_input_handler.size.x = 16 - note_tail.points[1].x
	tail_input_handler.position.x = -8 + note_tail.points[1].x
	
	var idx: int
	if mouse_drag:
		var arr = note_track.get_children()
		arr.sort_custom(func(a, b): return a.mouse_drag_time < b.mouse_drag_time)
		idx = arr.find(self)
	else:
		Difficulty.get_chart_notes().sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
		idx = Difficulty.get_chart_notes().find(data)
	if get_index() != idx: note_track.move_child(self, idx)

func update_visual():
	voice_icon.set_visible(data.has('trigger_voice'))
	
	# Ghost Notes
	modulate.a = 0.3 if data['note_modifier'] == LevelEditor.NOTETYPE.GHOST else 1.0
	
	# Auto Notes
	scale = Vector2(0.5,0.5) if data['note_modifier'] == LevelEditor.NOTETYPE.AUTO else Vector2(1.0,1.0)
	note_body.self_modulate = Color.LIGHT_GRAY if data['note_modifier'] == LevelEditor.NOTETYPE.AUTO else UI.colors[data['input_type']]
	
	# Hold Notes
	note_tail.default_color = UI.colors[data['input_type']]
	note_tail.set_visible(data['note_modifier'] == LevelEditor.NOTETYPE.HOLD)
	
	# Bomb Notes
	note_body_bomb.set_visible(data['note_modifier'] == LevelEditor.NOTETYPE.BOMB)
	
	# Update Tooltip
	input_handler.tooltip_text = str(data).replace(", ", "\r\n")\
	.replace("{", "").replace("}", "").replace("\"", "")

func _process(_delta):
	set_visible(global_position.x >= 0 and global_position.x < 1920)
	
	if global_position.x >= 960 and !hit:
		EventManager.editor_note_hit.emit(data)
		hit = true
	elif global_position.x < 960 and hit:
		hit = false

func _on_input_handler_gui_input(event):
	# Note Dragging
	match LevelEditor.current_tool:
		LevelEditor.TOOL.POINT:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					if event.is_pressed():
						note_selector.hide()
						note_selector.dragging_area = false
						if LevelEditor.selected_notes.has(self):
							for note: EditorNote in LevelEditor.selected_notes:
								note.mouse_drag = true
								note.mouse_drag_time = note.data['timestamp']
						else:
							mouse_drag = true
							mouse_drag_time = data['timestamp']
					elif mouse_drag:
						note_selector.show()
						# Check if notes exist
						if LevelEditor.selected_notes.has(self):
							var arr: Array
							for note: EditorNote in LevelEditor.selected_notes:
								note.mouse_drag = false
								arr.append_array(Difficulty.get_chart_notes().filter(check_note_exists_drag.bind(note.mouse_drag_time)))
							
							if arr.is_empty():
								Editor.level_changed = true
								for note: EditorNote in LevelEditor.selected_notes:
									var difference = note.data.get('hold_end_timestamp', note.data['timestamp']) - note.data['timestamp']
									if note.data.has('hold_end_timestamp'): note.data['hold_end_timestamp'] = note.mouse_drag_time + difference
									note.data['timestamp'] = note.mouse_drag_time
								
								# Update Tooltip Only
								input_handler.tooltip_text = str(data).replace(", ", "\r\n")\
								.replace("{", "").replace("}", "").replace("\"", "")
							else:
								Console.log({"message": "Notes already exist..."})
							
							for note: EditorNote in LevelEditor.selected_notes:
								note.update_position()
						else:
							mouse_drag = false
							var arr = Difficulty.get_chart_notes().filter(check_note_exists_drag.bind(mouse_drag_time))
							
							if arr.is_empty():
								Editor.level_changed = true
								var difference = data.get('hold_end_timestamp', data['timestamp']) - data['timestamp']
								if data.has('hold_end_timestamp'): data['hold_end_timestamp'] = mouse_drag_time + difference
								data['timestamp'] = mouse_drag_time
								
								# Update Tooltip Only
								input_handler.tooltip_text = str(data).replace(", ", "\r\n")\
								.replace("{", "").replace("}", "").replace("\"", "")
							else:
								Console.log({"message": "Note already exists..."})
							
							update_position()
				elif event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
					# Context Menu
					if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
						context_menu.set_item_disabled(context_menu.get_item_index(HOLD), true)
					else: context_menu.set_item_disabled(context_menu.get_item_index(HOLD), false)
					
					context_menu.position = get_global_mouse_position()
					context_menu.popup()
			
			if event is InputEventMouseMotion and mouse_drag:
				var difference = LevelEditor.get_mouse_timestamp(event.global_position.x) - mouse_drag_time
				if LevelEditor.selected_notes.has(self):
					for note: EditorNote in LevelEditor.selected_notes:
						note.mouse_drag_time += difference
						note.update_position()
				else:
					mouse_drag_time += difference
					update_position()
		LevelEditor.TOOL.MODIFY:
			if event is InputEventMouseButton and event.is_pressed():
				var modifier: int = 0 if data['note_modifier'] == LevelEditor.NOTETYPE.HOLD else data['note_modifier']
				
				if event.button_index == MOUSE_BUTTON_LEFT:
					modifier += 1
					if modifier == LevelEditor.NOTETYPE.HOLD:
						modifier = LevelEditor.NOTETYPE.NORMAL
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					modifier -= 1
					if modifier == LevelEditor.NOTETYPE.HOLD:
						modifier = LevelEditor.NOTETYPE.GHOST
				else:
					return
				
				modifier = wrapi(modifier, 0, LevelEditor.NOTETYPE.keys().size()-3)
				if modifier == LevelEditor.NOTETYPE.NORMAL and data.has('hold_end_timestamp'):
					modifier = LevelEditor.NOTETYPE.HOLD
				
				set_note_type(modifier)
		LevelEditor.TOOL.HOLD:
			if data['note_modifier'] != 0 and data['note_modifier'] != LevelEditor.NOTETYPE.HOLD: return
			
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					if data['note_modifier'] == LevelEditor.NOTETYPE.NORMAL:
						data.get_or_add('hold_end_timestamp', data['timestamp'])
						data['note_modifier'] = LevelEditor.NOTETYPE.HOLD
						update_visual()
					mouse_drag = true
				elif mouse_drag:
					mouse_drag = false
					if data['hold_end_timestamp'] <= data['timestamp']:
						data.erase('hold_end_timestamp')
						data['note_modifier'] = 0
			
			if event is InputEventMouseMotion and mouse_drag:
				var difference = LevelEditor.get_mouse_timestamp(event.global_position.x) - data['hold_end_timestamp']
				data['hold_end_timestamp'] = clampf(data['hold_end_timestamp'] + difference, data['timestamp'], LevelEditor.song_length - Config.settings['song_offset'])
				update_position()
		LevelEditor.TOOL.VOICE:
			if event is InputEventMouseButton and event.is_pressed():
				if data.has('trigger_voice'):
					data.erase('trigger_voice')
				else:
					data['trigger_voice'] = true
				update_visual()

func delete_note():
	var idx = Difficulty.get_chart_notes().find(data)
	Console.log({"message": "Deleting note at %s (index %s)" % [data['timestamp'],idx]})
	Difficulty.get_chart_notes().remove_at(idx)
	LevelEditor.selected_notes.erase(self)
	Editor.level_changed = true
	Util.free_node(self)

func check_selected():
	selected_visual.set_visible(selected)

func check_note_exists_drag(note, new_note_timestamp):
	var snapped_note_check = Math.beat_to_secs_dynamic((snappedf(Math.secs_to_beat_dynamic(note['timestamp']), 1.0 / LevelEditor.snapping_factor)
	if LevelEditor.snapping_allowed else Math.secs_to_beat_dynamic(note['timestamp'])))
	return snappedf(snapped_note_check, 0.001) == new_note_timestamp

func _on_context_menu_id_pressed(id: int):
	run_action(id)

func run_action(id: int):
	match id:
		DELETE:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				note_selector.group_delete_notes()
			else:
				delete_note()
		GHOST:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				var all_modified: bool = true
				for i in LevelEditor.selected_notes.size():
					var note: EditorNote = LevelEditor.selected_notes[i]
					
					if note.data['note_modifier'] != LevelEditor.NOTETYPE.GHOST:
						all_modified = false
						note.set_note_type(LevelEditor.NOTETYPE.GHOST)
					
					if i == LevelEditor.selected_notes.size()-1 and all_modified:
						for n: EditorNote in LevelEditor.selected_notes:
							n.set_note_type(LevelEditor.NOTETYPE.NORMAL)
			else:
				set_note_type(LevelEditor.NOTETYPE.GHOST)
		AUTO:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				var all_modified: bool = true
				for i in LevelEditor.selected_notes.size():
					var note: EditorNote = LevelEditor.selected_notes[i]
					
					if note.data['note_modifier'] != LevelEditor.NOTETYPE.AUTO:
						all_modified = false
						note.set_note_type(LevelEditor.NOTETYPE.AUTO)
					
					if i == LevelEditor.selected_notes.size()-1 and all_modified:
						for n: EditorNote in LevelEditor.selected_notes:
							n.set_note_type(LevelEditor.NOTETYPE.NORMAL)
			else:
				set_note_type(LevelEditor.NOTETYPE.AUTO)
		BOMB:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				var all_modified: bool = true
				for i in LevelEditor.selected_notes.size():
					var note: EditorNote = LevelEditor.selected_notes[i]
					
					if note.data['note_modifier'] != LevelEditor.NOTETYPE.BOMB:
						all_modified = false
						note.set_note_type(LevelEditor.NOTETYPE.BOMB)
					
					if i == LevelEditor.selected_notes.size()-1 and all_modified:
						for n: EditorNote in LevelEditor.selected_notes:
							n.set_note_type(LevelEditor.NOTETYPE.NORMAL)
			else:
				set_note_type(LevelEditor.NOTETYPE.BOMB)
		VOICE:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				for note: EditorNote in LevelEditor.selected_notes:
					if note.data.has('trigger_voice'):
						note.data.erase('trigger_voice')
					else:
						note.data['trigger_voice'] = true
					note.update_visual()
			else:
				if data.has('trigger_voice'):
					data.erase('trigger_voice')
				else:
					data['trigger_voice'] = true
				update_visual()
			
			update_visual()
			update_position()
	Editor.level_changed = true

func set_note_type(note_type_enum: int):
	if data['note_modifier'] == note_type_enum:
		if data.has('hold_end_timestamp'): data['note_modifier'] = LevelEditor.NOTETYPE.HOLD
		else: data['note_modifier'] = LevelEditor.NOTETYPE.NORMAL  
	else: 
		data['note_modifier'] = note_type_enum
	update_visual()
	Editor.level_changed = true
