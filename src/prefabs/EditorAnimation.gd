extends Node2D

@onready var input_handler = $InputHandler

@onready var preview_tooltip = $"../../../../../PreviewToolTip"
@onready var animation_preview = preview_tooltip.get_node("AnimationPreview/Sprite")
@onready var keyframe_info_label = preview_tooltip.get_node("KeyframeInfoLabel")

@onready var character = $"../../../../../Preview/Character"

var data: Dictionary
var preview_frame_value: float = 0.0

func _ready():
	EventManager.editor_update_notespeed.connect(update_position)

func setup(keyframe_data: Dictionary):
	data = keyframe_data
	update_position()
	
	var tooltip_data = data.duplicate()
	tooltip_data.erase('animations')
	tooltip_data.erase('sheet_data')
	tooltip_data.erase('scale_multiplier')
	
	input_handler.tooltip_text = str(tooltip_data).replace(", ", "\r\n")\
	.replace("{", "").replace("}", "").replace("\"", "")
	
	if Config.keyframes['loops'].is_empty() and LevelEditor.song_position_offset > data['timestamp']:
		character.change_animation(character.tsevent.index)

func update_position():
	position.x = -(data['timestamp'] * LevelEditor.note_speed_mod)

func _process(_delta):
	if preview_tooltip.visible and keyframe_info_label.text == data['animations'].normal:
		preview_frame_value = wrapf(preview_frame_value + 0.075, 0.0, float(data['sheet_data'].total))
		animation_preview.frame = int(preview_frame_value)

func _on_input_handler_mouse_entered():
	# Info
	keyframe_info_label.text = data['animations'].normal
	
	# Set Visuals
	animation_preview.texture = Assets.get_asset(data['animations'].normal)
	animation_preview.set_vframes(data['sheet_data'].v)
	animation_preview.set_hframes(data['sheet_data'].h)
	animation_preview.set_scale(Vector2(data.get('scale_multiplier', 1), data.get('scale_multiplier', 1)))
	animation_preview.frame = 0
	
	# Position Tooltip
	preview_tooltip.position = global_position
	preview_tooltip.show()

func _on_input_handler_mouse_exited():
	preview_tooltip.hide()

func _on_input_handler_gui_input(event: InputEvent):
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	match event.button_index:
		MOUSE_BUTTON_LEFT: pass
		MOUSE_BUTTON_RIGHT:
			var idx = Config.keyframes['loops'].find(data)
			Console.log({"message": "Deleting animation %s at %s (index %s)" % [self,data['timestamp'],idx]})
			Config.keyframes['loops'].remove_at(idx)
			Editor.level_changed = true
			Util.free_node(self)
			
			if Config.keyframes['loops'].is_empty() or LevelEditor.song_position_offset <= data['timestamp']:
				character.change_animation(idx)
