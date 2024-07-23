extends Node2D

@onready var input_handler = $InputHandler
@onready var sound_test = $SoundTest

var data: Dictionary
var beat: float

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(_on_editor_update_bpm)

func setup(loop_data: Dictionary):
	data = loop_data
	beat = Math.secs_to_beat_dynamic(data['timestamp'])
	update_position()
	
	input_handler.tooltip_text = data['path']
	sound_test.stream = Assets.get_asset(data['path'])

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
		MOUSE_BUTTON_LEFT:
			if sound_test.stream: sound_test.play()
		MOUSE_BUTTON_RIGHT: delete_loop()

func delete_loop():
	var idx = Config.keyframes['sound_loop'].find(data)
	Console.log({"message": "Deleting Sound Loop at %s (index %s)" % [data['timestamp'],idx]})
	Config.keyframes['sound_loop'].remove_at(idx)
	Util.free_node(self)
