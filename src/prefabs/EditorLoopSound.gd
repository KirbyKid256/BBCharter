extends Node2D

@onready var input_handler = $InputHandler
@onready var sound_test = $SoundTest

var data: Dictionary

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(update_position)

func setup(loop_data: Dictionary):
	data = loop_data
	update_position()
	
	if typeof(data['path']) != TYPE_ARRAY: sound_test.stream = Assets.get_asset(data['path'])
	input_handler.tooltip_text = str(data).replace(", ", "\r\n")\
	.replace("{", "").replace("}", "").replace("\"", "")

func update_position():
	position.x = -(data['timestamp'] * LevelEditor.note_speed_mod)

func _on_input_handler_gui_input(event: InputEvent):
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if sound_test.stream: sound_test.play()
		MOUSE_BUTTON_RIGHT: get_parent().delete_keyframe(data)
