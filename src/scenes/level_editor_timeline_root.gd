extends Node2D

@onready var music: AudioStreamPlayer = $'../../Music'

var seek_speed: float

var translate_hold: bool
var translate_hold_input: String
var translate_hold_time: float

func _init():
	InputMap.add_action("ui_jump")
	for i in 10:
		var event = InputEventKey.new()
		event.keycode = KEY_0 + i
		InputMap.action_add_event("ui_jump", event)

func _process(delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960
	
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		translate_hold = false
		translate_hold_time = 0
		translate_hold_input = "ui_left" if Input.is_action_just_pressed("ui_left") else "ui_right"
	if translate_hold_input and Input.is_action_pressed(translate_hold_input):
		translate_hold_time += delta
	
	if not translate_hold and translate_hold_time >= 0.5:
		translate_hold = true
		translate_hold_time = 0
		timeline_translate(5.0) if translate_hold_input == "ui_left" else timeline_translate(-5.0)
	elif translate_hold and translate_hold_time >= 0.1:
		translate_hold_time = 0
		timeline_translate(5.0) if translate_hold_input == "ui_left" else timeline_translate(-5.0)

func _input(event):
	if not Editor.level_loaded: return
	if not LevelEditor.controls_enabled: return
	
	if event is InputEventMouseButton:
		# Ignore if mouse on in timeline
		if get_viewport().get_mouse_position().y < 888: return
		
		# Timeline Zooming
		if event.is_command_or_control_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				LevelEditor.note_speed_mod = clampf(LevelEditor.note_speed_mod + 10, 100, 1000)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				LevelEditor.note_speed_mod = clampf(LevelEditor.note_speed_mod - 10, 100, 1000)
			
			EventManager.editor_update_notespeed.emit()
			return
		
		# Mouse Scroll Seek
		seek_speed = (LevelEditor.song_beats_per_second / 8) if not event.alt_pressed else 0.005
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			timeline_translate(seek_speed)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			timeline_translate(-seek_speed)
	
	if event is InputEventKey:
		# Seek to beginning / End
		if event.is_action_pressed("ui_home"):
			timeline_seek(0.0)
		if event.is_action_pressed("ui_end"):
			timeline_seek(LevelEditor.song_length)
		
		# Jump to different points
		if event.is_action_pressed("ui_jump"):
			timeline_seek((float(event.keycode - KEY_0) / 10.0) * LevelEditor.song_length)
		
		# Fast Seek +10
		if event.is_action_pressed("ui_left"):
			timeline_translate(5.0)
		if event.is_action_pressed("ui_right"):
			timeline_translate(-5.0)
	
	if event is InputEventPanGesture:
		if get_parent().get_global_rect().has_point(get_viewport().get_mouse_position()):
			# Zooming
			if event.is_command_or_control_pressed():
				LevelEditor.note_speed_mod = clampf(LevelEditor.note_speed_mod + (10 * event.delta.y), 100, 1000)
				EventManager.editor_update_notespeed.emit()
			else:
				# Seeking
				timeline_translate(0.125 * event.delta.x)

func timeline_translate(value):
	LevelEditor.song_position_raw = clampf(LevelEditor.song_position_raw + value, 0.0, LevelEditor.song_length)
	music.seek(LevelEditor.song_position_raw)
	LevelEditor.pause_position = LevelEditor.song_position_raw

func timeline_seek(value):
	LevelEditor.song_position_raw = clampf(value, 0.0, LevelEditor.song_length)
	music.seek(LevelEditor.song_position_raw)
	LevelEditor.pause_position = LevelEditor.song_position_raw
