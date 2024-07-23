extends Node2D

var data: Dictionary
var beat: float

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(_on_editor_update_bpm)

func setup(shutter_data: Dictionary):
	data = shutter_data
	beat = Math.secs_to_beat_dynamic(data['timestamp'])
	update_position()

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
			var idx = Config.keyframes['shutter'].find(data)
			Console.log({"message": "Deleting Shutter at %s (index %s)" % [data['timestamp'],idx]})
			Config.keyframes['shutter'].remove_at(idx)
			Util.free_node(self)
