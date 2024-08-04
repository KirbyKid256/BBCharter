extends Node2D

@onready var input_handler = $InputHandler
@onready var background = $"../../../../../Preview/Background"

var data: Dictionary
var beat: float

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(_on_editor_update_bpm)

func setup(background_data: Dictionary):
	data = background_data
	beat = Math.secs_to_beat_dynamic(data['timestamp'])
	update_position()
	
	input_handler.tooltip_text = str(data).replace(", ", "\r\n")\
	.replace("{", "").replace("}", "").replace("\"", "")
	
	if Config.keyframes['background'].is_empty() and LevelEditor.song_position_offset > data['timestamp']:
		background.change_background(background.tsevent.index)

func _on_editor_update_bpm():
	data['timestamp'] = Math.beat_to_secs_dynamic(beat)
	beat = Math.secs_to_beat_dynamic(data['timestamp'])
	update_position()

func update_position():
	position.x = -(data['timestamp'] * LevelEditor.note_speed_mod)

func _on_input_handler_gui_input(event: InputEvent):
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	match event.button_index:
		MOUSE_BUTTON_LEFT: pass
		MOUSE_BUTTON_RIGHT:
			var idx = Config.keyframes['background'].find(data)
			Console.log({"message": "Deleting Background at %s (index %s)" % [data['timestamp'],idx]})
			Config.keyframes['background'].remove_at(idx)
			Editor.level_changed = true
			Util.free_node(self)
			
			if Config.keyframes['background'].is_empty():
				background.change_background(idx)
