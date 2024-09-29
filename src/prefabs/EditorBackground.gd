extends Node2D

@onready var input_handler = $InputHandler
@onready var background = $"../../../../../Preview/Background"

var data: Dictionary

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(update_position)

func setup(background_data: Dictionary):
	data = background_data
	update_position()
	
	input_handler.tooltip_text = str(data).replace(", ", "\r\n")\
	.replace("{", "").replace("}", "").replace("\"", "")
	
	if Config.keyframes.background.is_empty() and LevelEditor.song_position_offset > data.timestamp:
		background.change_background(background.tsevent.index)

func update_position():
	position.x = -(data.timestamp * LevelEditor.note_speed_mod)

func _on_input_handler_gui_input(event: InputEvent):
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	match event.button_index:
		MOUSE_BUTTON_LEFT: pass
		MOUSE_BUTTON_RIGHT: get_parent().delete_keyframe(data)
