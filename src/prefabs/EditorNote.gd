extends Node2D
class_name EditorNote

enum {DELETE,GHOST,AUTO,BOMB,VOICE,HOLD}

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
var mouse_drag_hold: bool
var mouse_drag_hold_time: float

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(update_position)

func setup(editor_note_data):
	data = editor_note_data
	mouse_drag_time = data.timestamp
	mouse_drag_hold_time = data.get('hold_end_timestamp', data.timestamp)
	
	update_visual()
	update_position()
	if global_position.x >= 960: hit = true

func update_position():
	var hold_end_timestamp = (mouse_drag_hold_time if mouse_drag_hold else data.get('hold_end_timestamp', data.timestamp)) - data.timestamp
	note_tail.points[1].x = -(hold_end_timestamp * LevelEditor.note_speed_mod)
	
	if mouse_drag:
		position.x = -(mouse_drag_time * LevelEditor.note_speed_mod)
		note_tail.points[1].x = -(hold_end_timestamp * LevelEditor.note_speed_mod)
	else:
		position.x = -(data.timestamp * LevelEditor.note_speed_mod)
		note_tail.points[1].x = -(hold_end_timestamp * LevelEditor.note_speed_mod)
	
	tail_input_handler.size.x = 16 - note_tail.points[1].x
	tail_input_handler.position.x = -8 + note_tail.points[1].x
	
	if mouse_drag:
		var arr = get_parent().get_children()
		arr.sort_custom(func(a, b): return a.mouse_drag_time < b.mouse_drag_time)
		move_to_front()
	else:
		Difficulty.get_chart_notes().sort_custom(func(a, b): return a.timestamp < b.timestamp)
		var idx: int = Difficulty.get_chart_notes().find(data)
		if get_index() != idx: get_parent().move_child(self, idx)

func update_visual():
	voice_icon.set_visible(data.has('trigger_voice'))
	
	# Ghost Notes
	modulate.a = 0.3 if data.note_modifier == LevelEditor.NOTETYPE.GHOST else 1.0
	
	# Auto Notes
	scale = Vector2(0.5,0.5) if data.note_modifier == LevelEditor.NOTETYPE.AUTO else Vector2(1.0,1.0)
	note_body.self_modulate = Color.LIGHT_GRAY if data.note_modifier == LevelEditor.NOTETYPE.AUTO else UI.colors[data.input_type]
	
	# Hold Notes
	note_tail.default_color = UI.colors[data.input_type]
	note_tail.set_visible(data.note_modifier == LevelEditor.NOTETYPE.HOLD or mouse_drag_hold)
	
	# Bomb Notes
	note_body_bomb.set_visible(data.note_modifier == LevelEditor.NOTETYPE.BOMB)
	
	# Update Tooltip
	input_handler.tooltip_text = str(data).replace(", ", "\r\n")\
	.replace("{", "").replace("}", "").replace("\"", "")

func _process(_delta):
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
								note.mouse_drag_time = note.data.timestamp
						else:
							mouse_drag = true
							mouse_drag_time = data.timestamp
					elif mouse_drag:
						note_selector.show()
						# Check if notes exist
						if LevelEditor.selected_notes.has(self):
							var arr: Array
							for note: EditorNote in LevelEditor.selected_notes:
								note.mouse_drag = false
								arr.append_array(Difficulty.get_chart_notes().filter(check_note_exists_drag.bind(note.mouse_drag_time)))
							for note: EditorNote in LevelEditor.selected_notes:
								arr.erase(note.data)
							
							for note: EditorNote in LevelEditor.selected_notes: note.update_position()
							
							if arr.is_empty():
								for note: EditorNote in LevelEditor.selected_notes: get_parent().move_note(note.data, note.mouse_drag_time)
							else:
								Console.log({"message": "Notes already exist..."})
						else:
							mouse_drag = false
							var arr = Difficulty.get_chart_notes().filter(check_note_exists_drag.bind(mouse_drag_time))
							
							update_position()
							if arr.is_empty():
								get_parent().move_note(data, mouse_drag_time)
							else:
								if arr[0].timestamp != data.timestamp: Console.log({"message": "Note already exists..."})
				
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
				var modifier: int = 0 if data.note_modifier == LevelEditor.NOTETYPE.HOLD else data.note_modifier
				var old_modifier: int = modifier
				
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
				
				Global.undo_redo.create_action("Modify Note")
				Global.undo_redo.add_do_method(get_parent().modify_note.bind(data, modifier))
				Global.undo_redo.add_undo_method(get_parent().modify_note.bind(data, old_modifier))
				Global.undo_redo.commit_action()
		LevelEditor.TOOL.HOLD:
			if data.note_modifier != 0 and data.note_modifier != LevelEditor.NOTETYPE.HOLD: return
			
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					mouse_drag_hold = true
					update_visual()
				elif mouse_drag_hold:
					mouse_drag_hold = false
					var old_time: float = data.duplicate().get("hold_end_timestamp", data.timestamp)
					Global.undo_redo.create_action("Hold Note")
					Global.undo_redo.add_do_method(get_parent().hold_note.bind(data, mouse_drag_hold_time))
					Global.undo_redo.add_undo_method(get_parent().hold_note.bind(data, old_time))
					Global.undo_redo.commit_action()
			
			if event is InputEventMouseMotion and mouse_drag_hold:
				var difference = LevelEditor.get_mouse_timestamp(event.global_position.x) - mouse_drag_hold_time
				mouse_drag_hold_time = clampf(mouse_drag_hold_time + difference, data.timestamp, LevelEditor.song_length - Config.settings.song_offset)
				update_position()
		LevelEditor.TOOL.VOICE:
			if event is InputEventMouseButton and event.is_pressed():
				Global.undo_redo.create_action("Voice Note")
				Global.undo_redo.add_do_method(get_parent().voice_note.bind(data))
				Global.undo_redo.add_undo_method(get_parent().voice_note.bind(data))
				Global.undo_redo.commit_action()

func check_selected():
	selected_visual.set_visible(selected)

func check_note_exists_drag(note, new_note_timestamp):
	return snappedf(note.timestamp, 0.001) == snappedf(new_note_timestamp, 0.001)

func run_action(id: int):
	match id:
		DELETE:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				note_selector.group_remove_notes()
			else:
				Global.undo_redo.create_action("Remove Note")
				Global.undo_redo.add_do_method(get_parent().remove_note.bind(data))
				Global.undo_redo.add_undo_method(get_parent().add_note.bind(data))
				Global.undo_redo.commit_action()
		GHOST:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				get_parent().modify_note(data, LevelEditor.NOTETYPE.GHOST)
			else:
				var old_modifier = data.duplicate().note_modifier
				Global.undo_redo.create_action("Modify Note")
				Global.undo_redo.add_do_method(get_parent().modify_note.bind(data, LevelEditor.NOTETYPE.GHOST))
				Global.undo_redo.add_undo_method(get_parent().modify_note.bind(data, old_modifier))
				Global.undo_redo.commit_action()
		AUTO:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				get_parent().modify_note(data, LevelEditor.NOTETYPE.AUTO)
			else:
				var old_modifier: int = data.duplicate().note_modifier
				Global.undo_redo.create_action("Modify Note")
				Global.undo_redo.add_do_method(get_parent().modify_note.bind(data, LevelEditor.NOTETYPE.AUTO))
				Global.undo_redo.add_undo_method(get_parent().modify_note.bind(data, old_modifier))
				Global.undo_redo.commit_action()
		BOMB:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				get_parent().modify_note(data, LevelEditor.NOTETYPE.BOMB)
			else:
				var old_modifier = data.duplicate().note_modifier
				Global.undo_redo.create_action("Modify Note")
				Global.undo_redo.add_do_method(get_parent().modify_note.bind(data, LevelEditor.NOTETYPE.BOMB))
				Global.undo_redo.add_undo_method(get_parent().modify_note.bind(data, old_modifier))
				Global.undo_redo.commit_action()
		VOICE:
			if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
				get_parent().voice_note(data)
			else:
				Global.undo_redo.create_action("Voice Note")
				Global.undo_redo.add_do_method(get_parent().voice_note.bind(data))
				Global.undo_redo.add_undo_method(get_parent().voice_note.bind(data))
				Global.undo_redo.commit_action()
		HOLD:
			var old_time: float = data.duplicate().get("hold_end_timestamp", data.timestamp)
			Global.undo_redo.create_action("Hold Note")
			Global.undo_redo.add_do_method(get_parent().hold_note.bind(data, LevelEditor.get_timestamp()))
			Global.undo_redo.add_undo_method(get_parent().hold_note.bind(data, old_time))
			Global.undo_redo.commit_action()

func set_note_type(note_type_enum: int):
	if data.note_modifier == note_type_enum:
		if data.has('hold_end_timestamp'): data.note_modifier = LevelEditor.NOTETYPE.HOLD
		else: data.note_modifier = LevelEditor.NOTETYPE.NORMAL  
	else: 
		data.note_modifier = note_type_enum
	update_visual()
