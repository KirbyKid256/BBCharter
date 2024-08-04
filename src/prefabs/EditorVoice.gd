extends Node2D

@onready var input_handler: Control = $InputHandler
@onready var context_menu: PopupMenu = $ContextMenu

var data: Dictionary
var beat: float

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(_on_editor_update_bpm)

func setup(voice_data: Dictionary):
	data = voice_data
	beat = Math.secs_to_beat_dynamic(data['timestamp'])
	update_position()
	
	input_handler.tooltip_text = str(data['voice_paths']).replace(", ", "\r\n")\
	.replace("[", "").replace("]", "").replace("\"", "")

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
			var idx = Config.keyframes['voice_bank'].find(data)
			Console.log({"message": "Deleting Voice Bank at %s (index %s)" % [data['timestamp'],idx]})
			Config.keyframes['voice_bank'].remove_at(idx)
			Editor.level_changed = true
			Util.free_node(self)
