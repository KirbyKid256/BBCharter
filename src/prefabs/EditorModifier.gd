extends Node2D

@onready var modifier_icon: Sprite2D = $ModifierIcon
@onready var input_handler: Control = $InputHandler
@onready var bpm_field: LineEdit = $BpmField

#BPM Stuff
@onready var music: AudioStreamPlayer = $'../../../../../Music'
@onready var modifiers: Node2D = get_parent()

var data: Dictionary
var beat: float

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(_on_editor_update_bpm)

func _input(event: InputEvent):
	if bpm_field.visible and event is InputEventMouseButton:
		if (get_window().get_mouse_position().x < bpm_field.global_position.x
		or get_window().get_mouse_position().x > bpm_field.global_position.x + bpm_field.size.x
		or get_window().get_mouse_position().y < bpm_field.global_position.y
		or get_window().get_mouse_position().y > bpm_field.global_position.y + bpm_field.size.y):
			_on_bpm_field_text_submitted(bpm_field.text)

func setup(modifier_data: Dictionary):
	data = modifier_data
	beat = Math.secs_to_beat_dynamic(data['timestamp'])
	bpm_field.text = str(data['bpm'])
	update_position()
	
	input_handler.tooltip_text = str(data).replace(", ", "\r\n")\
	.replace("{", "").replace("}", "").replace("\"", "")

func _on_editor_update_bpm():
	data['timestamp'] = Math.beat_to_secs_dynamic(beat)
	beat = Math.secs_to_beat_dynamic(data['timestamp'])
	update_position()

func update_position():
	position.x = -(data.get('timestamp', 0.0) * LevelEditor.note_speed_mod)

func set_bpm(value: float):
	# Set new bpm and store previous for note ratio
	var last_bpm = data['bpm']
	data['bpm'] = value
	
	if last_bpm == value: return # Do nothing if bpm not changed
	input_handler.tooltip_text = str(value)
	
	# Reinit the editor music and indicator elements
	LevelEditor.calculate_song_info(music.stream)
	EventManager.emit_signal('editor_update_bpm')
	Console.log({"message": "Bpm set to %s" % value})

func _on_input_handler_gui_input(event: InputEvent):
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			LevelEditor.controls_enabled = false
			modifier_icon.hide()
			input_handler.hide()
			bpm_field.show()
		MOUSE_BUTTON_RIGHT:
			if data['timestamp'] == 0:
				Console.log({"message": "You can't delete this BPM modifier", "type": 2})
				return
			else:
				var idx = Config.keyframes['modifiers'].find(data)
				Console.log({"message": "Deleting BPM Change at %s (index %s)" % [data['timestamp'],idx]})
				Config.keyframes['modifiers'].remove_at(idx)
				Editor.project_changed = true
				Util.free_node(self)
				
				LevelEditor.calculate_song_info(music.stream)
				EventManager.emit_signal('editor_update_bpm')

func _on_bpm_field_text_submitted(new_text: String):
	set_bpm(float(new_text))
	LevelEditor.controls_enabled = true
	
	modifier_icon.show()
	input_handler.show()
	bpm_field.hide()
