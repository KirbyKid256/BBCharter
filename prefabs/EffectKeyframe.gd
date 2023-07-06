extends Node2D

var data: Dictionary

var move_pos: bool
var mouse_pos: float
var mouse_pos_start: float
var mouse_pos_end: float
var selected_key: Node2D

func _ready():
	Events.update_notespeed.connect(update_position)

func _process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if Global.snapping_allowed: mouse_pos = Global.get_mouse_timestamp_snapped()
		else: mouse_pos = Global.get_mouse_timestamp()
		if move_pos and selected_key != null:
			selected_key['data']['timestamp'] = mouse_pos
			Save.keyframes['effects'].sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
			update_position()

func setup(keyframe_data):
	move_pos = false
	data = keyframe_data
	$InputHandler.tooltip_text = data['path']
	$Thumb.texture = Assets.get_asset(data['path'])
	if $Thumb.texture:
		$Thumb.hframes = data['sheet_data']["h"] # Get hframes from preset
		$Thumb.vframes = data['sheet_data']["v"] # Get vframes from preset
		$Thumb.texture_filter = TEXTURE_FILTER_LINEAR
		var frame_size = $Thumb.texture.get_size() / Vector2($Thumb.hframes, $Thumb.vframes)
		var ratio = 104
		scale = Vector2(ratio * 1.777,ratio)/frame_size
		$InputHandler.size = frame_size
		$InputHandler.position = -$InputHandler.size/2
		update_position()

func update_position():
	position.x = -((data['timestamp'] - Global.offset - Global.bpm_offset) * Global.note_speed)

func _on_input_handler_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					selected_key = self
					if event.double_click:
						Popups.id = 1
						Events.emit_signal('add_effect_to_timeline', data)
				MOUSE_BUTTON_MIDDLE:
					print(Save.keyframes['effects'].find(data))
				MOUSE_BUTTON_RIGHT:
					Global.project_saved = false
					Timeline.delete_keyframe('effects', self, Save.keyframes['effects'].find(data))
		else:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					mouse_pos_end = mouse_pos
					for key in Timeline.effects_track.get_children(): if key != selected_key: if snappedf(key['data']['timestamp'], 0.001) == snappedf(selected_key['data']['timestamp'], 0.001):
						if Global.replacing_allowed:
							Timeline.delete_keyframe('effects', key, Save.keyframes['effects'].find(key['data']))
						else:
							print('Effect already exists at %s' % [snappedf(mouse_pos_end, 0.001)])
							selected_key['data']['timestamp'] = mouse_pos_start
							break
					Save.keyframes['effects'].sort_custom(func(a, b): return a['timestamp'] < b['timestamp']); update_position()
					if mouse_pos_start != selected_key['data']['timestamp']: Global.project_saved = false
					selected_key = null; mouse_pos_start = 0; mouse_pos_end = 0; move_pos = false

func _on_mouse_exited():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): move_pos = true