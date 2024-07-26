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
@onready var note_body_bomb: Sprite2D = $NoteBodyBomb

var hit: bool
var data: Dictionary
var beat: float
var hold_beat: float
var selected: bool
var last_type: int

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(_on_editor_update_bpm)

func setup(editor_note_data):
	data = editor_note_data
	beat = Math.secs_to_beat_dynamic(data['timestamp'])
	hold_beat = Math.secs_to_beat_dynamic(data.get('hold_end_timestamp', data['timestamp']))
	update_visual()
	update_position()

func _on_editor_update_bpm():
	data['timestamp'] = Math.beat_to_secs_dynamic(beat)
	beat = Math.secs_to_beat_dynamic(data['timestamp'])
	
	if data.has('hold_end_timestamp'):
		data['hold_end_timestamp'] = Math.beat_to_secs_dynamic(hold_beat)
		hold_beat = Math.secs_to_beat_dynamic(data['hold_end_timestamp'])
	
	update_position()

func update_position():
	position.x = -(data['timestamp'] * LevelEditor.note_speed_mod)
	
	var hold_end_timestamp = data.get('hold_end_timestamp', data['timestamp']) - data['timestamp']
	note_tail.points[1].x = -(hold_end_timestamp * LevelEditor.note_speed_mod)

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
		EventManager.emit_signal('editor_note_hit', data)
		hit = true
	elif global_position.x < 960 and hit:
		hit = false

func _on_input_handler_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if LevelEditor.selected_notes.size() > 0 and LevelEditor.selected_notes.has(self):
					context_menu.set_item_disabled(context_menu.get_item_index(HOLD), true)
				else: context_menu.set_item_disabled(context_menu.get_item_index(HOLD), false)
				
				context_menu.position = get_global_mouse_position()
				context_menu.popup()

func delete_note():
	var idx = Difficulty.get_chart_notes().find(data)
	Console.log({"message": "Deleting nogte at %s (index %s)" % [data['timestamp'],idx]})
	Difficulty.get_chart_notes().remove_at(idx)
	LevelEditor.selected_notes.erase(self)
	Editor.project_changed = true
	Util.free_node(self)

func check_selected():
	selected_visual.set_visible(selected)

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
		HOLD:
			if data['note_modifier'] == LevelEditor.NOTETYPE.NORMAL or data['note_modifier'] == LevelEditor.NOTETYPE.HOLD:
				data['note_modifier'] = LevelEditor.NOTETYPE.HOLD 
				
				if data['timestamp'] > LevelEditor.get_timestamp():
					print("Cannot do that >:("); return
				elif data['timestamp'] == LevelEditor.get_timestamp():
					data['note_modifier'] = LevelEditor.NOTETYPE.NORMAL 
					data.erase('hold_end_timestamp')
				
				data['hold_end_timestamp'] = LevelEditor.get_timestamp()
				hold_beat = Math.secs_to_beat_dynamic(data.get('hold_end_timestamp', data['timestamp']))
			
			update_visual()
			update_position()
	Editor.project_changed = true

func set_note_type(note_type_enum: int):
	if data['note_modifier'] == note_type_enum:
		if data.has('hold_end_timestamp'): data['note_modifier'] = LevelEditor.NOTETYPE.HOLD  
		else: data['note_modifier'] = LevelEditor.NOTETYPE.NORMAL  
	else: 
		data['note_modifier'] = note_type_enum
	update_visual()
	Editor.project_changed = true
