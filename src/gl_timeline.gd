extends Node

var note_controller: Node2D
var key_controller: Control

var beat_container: Node2D
var half_container: Node2D
var third_container: Node2D
var quarter_container: Node2D
var sixth_container: Node2D
var eighth_container: Node2D

var key_beat_container: Node2D
var key_half_container: Node2D
var key_third_container: Node2D
var key_quarter_container: Node2D
var key_sixth_container: Node2D
var key_eighth_container: Node2D

var note_container: Node2D

var shutter_track: Node2D
var animations_track: Node2D
var effects_track: Node2D
var backgrounds_track: Node2D
var modifier_track: Node2D
var sfx_track: Node2D
var oneshot_sound_track: Node2D
var voice_banks_track: Node2D

var note_scroller: Control

var inc_scale: float
var scroll: bool = false
var zoom_scale_range: Array = [100, 1000]

var note_timeline: Panel
var note_scroller_map: HBoxContainer
var key_timeline: ScrollContainer
var key_container: VBoxContainer
var timeline_root: Control
var shutter_timeline: Panel
var animations_timeline: Panel
var backgrounds_timeline: Panel
var modifier_timeline: Panel
var sound_loops_timeline: Panel
var one_shot_sound_timeline: Panel
var voice_bank_timeline: Panel


var marquee_selection: Node2D
var marquee_selection_area: Node2D
var marquee_active: bool = false
var marquee_point_a: Vector2 = Vector2(0,0)
var marquee_point_b: Vector2 = Vector2(0,0)
var marquee_visible: ColorRect

var timeline_ui: Array

func create_note(key: int):
	if not Global.project_loaded: return
	if Popups.open: return
	
	var time: float
	if Global.snapping_allowed: time = Global.get_timestamp_snapped()
	else: time = Global.song_pos
	if time < 0: time = 0
	
	# Check Note Exists
	for note in Timeline.note_container.get_children(): if snappedf(note.data['timestamp'], 0.001) == snappedf(time, 0.001):
		if Global.replacing_allowed:
			delete_note(note, Save.notes['charts'][Global.difficulty_index]['notes'].find(note.data))
		else:
			print('[Timeline] Note already exists at %s' % [snappedf(note.data['timestamp'], 0.001)])
			return
	
	# Create New Note
	var new_note_data = {'input_type':key, "note_modifier":0, 'timestamp':time }
	Global.current_chart.append(new_note_data)
	Global.current_chart.sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	Events.emit_signal("note_created", new_note_data)
	print('Added note ' + str(key) + ' at %s' % [snappedf(time, 0.001)])
	update_visuals()
	update_map()

func Add_hold(timesta: float):
	print(timesta)
	var target_note
	if Clipboard.selected_notes[0] != null:
		target_note = Clipboard.selected_notes[0]
	var note_nume = 0
	if target_note == null:
		print("No note selected")
	else:
		var new_note_data = {'hold_end_timestamp':timesta, 'input_type':target_note.data['input_type'], "note_modifier":3, 'timestamp':target_note.data['timestamp'] }
		delete_note(target_note, Save.notes['charts'][Global.difficulty_index]['notes'].find(target_note.data))
		Global.current_chart.append(new_note_data)
		Global.current_chart.sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
		Events.emit_signal("note_created", new_note_data)
		update_visuals()
		update_map()
		Clipboard.clear_clipboard()
		new_note_data=null
		target_note = null
		
	
func delete_note(note: Node2D, idx: int):
	Global.project_saved = false
	Events.emit_signal("note_deleted")
	print("Deleting note %s at %s (index %s)" % [note, note.data['timestamp'], idx])
	Global.current_chart.remove_at(idx)
	note.get_parent().remove_child(note); note.queue_free()
	update_visuals()
	update_map()

func delete_keyframe(section: String, node: Node2D, idx: int):
	if Save.keyframes[section].size() > 0:
		Global.project_saved = false
		print("Deleting %s %s at %s (index %s)" % [section, node, node.data['timestamp'], idx])
		Save.keyframes[section].remove_at(idx)
		node.get_parent().remove_child(node); node.queue_free()
	update_visuals()
	update_map()

func delete_keyframes(section: String, parent: Node):
	for child in parent.get_children(): delete_keyframe(section, child, 0)

func clamp_seek(value):
	Global.music.song_position_raw = clampf(Global.music.song_position_raw + value, 0.0, Global.song_length)
	Global.music.seek(Global.music.song_position_raw)
	Global.music.pause_pos = Global.music.song_position_raw
	note_scroller.value = Global.music.song_position_raw

func seek(value):
	Global.music.song_position_raw = value
	Global.music.seek(Global.music.song_position_raw)
	Global.music.pause_pos = Global.music.song_position_raw
	note_scroller.value = Global.music.song_position_raw

func reset():
	seek(0.0)

func clear_timeline():
	clear_notes_only()
	delete_keyframes('shutter', shutter_track)
	delete_keyframes('loops', animations_track)
	delete_keyframes('effects', effects_track)
	delete_keyframes('background', backgrounds_track)
	if Global.project_loaded: for child in modifier_track.get_children():
		if child.data['timestamp'] != 0: delete_keyframe('modifiers', child, 0)
	else: delete_keyframes('modifiers', modifier_track)
	delete_keyframes('sound_loop', sfx_track)
	delete_keyframes('sound_oneshot', oneshot_sound_track)
	delete_keyframes('voice_bank', voice_banks_track)

func clear_notes_only():
	print('Cleaning Notes Only')
	Global.current_chart.clear()
	Global.clear_children(note_container)

func update_visuals():
	print("Update Visuals!")
	var ref
	var ref_bg
	var ref_next
	var ref_thumb
	var ref_arr: Array = Timeline.animations_track.get_children()
	var note_arr: Array = Timeline.note_container.get_children()
	
	ref_arr.sort_custom(func(a, b): return a['data']['timestamp'] < b['data']['timestamp'])
	note_arr.sort_custom(func(a, b): return a['data']['timestamp'] < b['data']['timestamp'])
	
	for x in ref_arr.size():
		ref = ref_arr[x]
		#print("ref %s debug %s " % [x,ref.position.x])
		ref_bg = ref_arr[x].get_node("Background")
		ref_thumb = ref_arr[x].get_node("Thumb")
		
		if note_arr == null or note_arr.is_empty(): return
		
		if x+1 == ref_arr.size():
			ref_bg.size = ref_thumb.get_rect().size
			ref_bg.position = Vector2(-ref_bg.size.x, -ref_bg.size.y / 2) ## Reset size and pos
			ref_bg.size.x = abs(note_arr.back().position.x - ref.position.x) / ref.scale.x
			ref_bg.position.x += ref_thumb.get_rect().size.x
			ref_bg.position.y = ref_bg.size.y / 2
			break
		
		ref_next = ref_arr[x+1]
		
		ref_bg.size = ref_thumb.get_rect().size
		
		ref_bg.position = Vector2(-ref_bg.size.x, -ref_bg.size.y / 2) ## Reset size and pos
		ref_bg.size.x = abs(ref_next.position.x - ref.position.x) / ref.scale.x
		ref_bg.position.x += ref_thumb.get_rect().size.x
		ref_bg.position.y = ref_bg.size.y / 2

func update_map():
	var ref_arr: Array = Timeline.animations_track.get_children()
	var note_arr: Array = Timeline.note_container.get_children()
	
	if ref_arr == null or ref_arr.is_empty(): return
	if note_arr == null or note_arr.is_empty(): return
	
	ref_arr.sort_custom(func(a, b): return a['data']['timestamp'] < b['data']['timestamp'])
	note_arr.sort_custom(func(a, b): return a['data']['timestamp'] < b['data']['timestamp'])
	
	if Timeline.note_scroller_map.get_children().size() > 0:
		Global.clear_children(Timeline.note_scroller_map)
	
	for x in ref_arr.size():
		var cell = ColorRect.new()
		cell.color = ref_arr[x].get_node("Background").color; cell.color.a = 1.0
		
		# Cell size
		if x+1 == ref_arr.size(): cell.custom_minimum_size.x = abs(ref_arr[x].data['timestamp'] - note_arr.back().data['timestamp']) / Global.song_length
		else: cell.custom_minimum_size.x = abs(ref_arr[x].data['timestamp'] - ref_arr[x+1].data['timestamp']) / Global.song_length
		cell.custom_minimum_size.x *= timeline_root.size.x
		print("Cell %s | Timestamp: %s - SizeX: %s" % [x, ref_arr[x].data['timestamp'], cell.custom_minimum_size.x])
		Timeline.note_scroller_map.add_child(cell)
	
	var offset_start: float = ((Global.offset + ref_arr.front().data['timestamp']) / Global.song_length) * timeline_root.size.x
	var offset_end: float = timeline_root.size.x - offset_start
	
	var offset_end_cell = ColorRect.new()
	offset_end_cell.name = 'end_cell'
	offset_end_cell.color = Color.BLACK
	offset_end_cell.custom_minimum_size.x = offset_end
	
	var offset_start_cell = ColorRect.new()
	offset_start_cell.name = 'start_cell'
	offset_start_cell.color = Color.BLACK
	offset_start_cell.custom_minimum_size.x = offset_start
	
	Timeline.note_scroller_map.add_child(offset_end_cell)
	Timeline.note_scroller_map.add_child(offset_start_cell)
	
	Timeline.note_scroller_map.move_child(Timeline.note_scroller_map.get_node('start_cell'), 0)

func _input(event):
	if Popups.open or Global.lock_timeline: return
	#print(event)
	if event.is_action_pressed("key_0"):
		create_note(Enums.NOTE.Z)
	if event.is_action_pressed("key_1"):
		create_note(Enums.NOTE.X)
	if event.is_action_pressed("key_2"):
		create_note(Enums.NOTE.C)
	if event.is_action_pressed("key_3"):
		create_note(Enums.NOTE.V)
	if event.is_action_pressed("Hold_0"):
		if Global.snapping_allowed: Add_hold(Global.get_timestamp_snapped())
		else: Add_hold(Global.song_pos)
		
		
	if event is InputEventMouse:
		for x in timeline_ui:
			if check_gui_mouse(x):
				x.modulate = Color(1, 1, 1)
			else:
				x.modulate = Color(0.7, 0.7, 0.7)
		#note_timeline.modulate = Color(0.818, 0.818, 0.818)
		#print('Marquee Position:', marquee_selection.position)
		Timeline.marquee_selection.monitoring = marquee_active
		if marquee_active:
			if Global.current_tool == Enums.TOOL.MARQUEE:
				("Drag Marquee")
				marquee_point_b = event.position
				set_marquee(event, marquee_selection_area)
				#marquee_selection_area.position = marquee_selection.position
				#print(marquee_selection_area.transform.basis_xform_inv(marquee_point_b))
			#print("Marquee Drag")
		if check_gui_mouse(timeline_root):
			# Zooming
			Timeline.key_timeline.mouse_filter = Control.MOUSE_FILTER_STOP
			if event.get('button_index') != null:
				if event.is_command_or_control_pressed():
					Timeline.key_timeline.mouse_filter = Control.MOUSE_FILTER_IGNORE
					if event.button_index == MOUSE_BUTTON_WHEEL_UP:
						Global.note_speed = clampf(Global.note_speed + 10, zoom_scale_range[0], zoom_scale_range[1] )
					if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
						Global.note_speed = clampf(Global.note_speed - 10, zoom_scale_range[0], zoom_scale_range[1] )
					Events.emit_signal('update_notespeed')
					update_visuals()
					update_map()
				else:
					if check_gui_mouse(note_timeline):
						# Seeking
						inc_scale = (Global.zoom_factor / 16) if !event.alt_pressed else 0.005
						if event.button_index == MOUSE_BUTTON_WHEEL_UP:
							clamp_seek(inc_scale)
						if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
							clamp_seek(-inc_scale)
						
					if event.pressed:
						match event.button_index:
							MOUSE_BUTTON_LEFT:
								if Global.current_tool == Enums.TOOL.MARQUEE:
									print("Set Marquee")
									marquee_active = true
									marquee_point_a = event.position
									set_marquee(event, marquee_selection)
		if event is InputEventMouseButton and event.is_released():
			marquee_active = false
	if event is InputEventPanGesture:
		if check_gui_mouse(timeline_root):
			# Zooming
			if event.is_command_or_control_pressed():
				Global.note_speed = clampf(Global.note_speed + (10 * event.delta.y), zoom_scale_range[0], zoom_scale_range[1] )
				Events.emit_signal('update_notespeed')
			else:
				# Seeking
				inc_scale = (Global.zoom_factor / 8) if !event.alt_pressed else 0.005
				clamp_seek(inc_scale * event.delta.x)
	
	if event is InputEventKey:
		# Speed up / Slow down song
		if event.is_action_pressed("ui_up"):
			Global.music.pitch_scale = clampf(Global.music.pitch_scale + 0.1, 0.5, 2.0)
		if event.is_action_pressed("ui_down"):
			Global.music.pitch_scale = clampf(Global.music.pitch_scale - 0.1, 0.5, 2.0)
		
		# Seek to beginning / End
		if OS.get_name() == "macOS":
			if event.is_action_pressed("ui_end"): reset()
		else:
			if event.is_action_pressed("ui_home"): reset()
		if OS.get_name() == "macOS":
			if event.is_action_pressed("ui_home"): seek(Global.song_length)
		else:
			if event.is_action_pressed("ui_end"): seek(Global.song_length)
		
		# Fast Seek +5 AND Seek to beginning / End
		if event.is_action_pressed("ui_right"):
			if OS.get_name() == "macOS" and event.is_meta_pressed(): reset()
			else: clamp_seek(-5.0)
		if event.is_action_pressed("ui_left"):
			if OS.get_name() == "macOS" and event.is_meta_pressed(): seek(Global.song_length)
			else: clamp_seek(5.0)

func set_marquee(ev, obj):
	if Popups.open: return
	var local_to_timeline_panel = timeline_root.get_local_mouse_position()
	if obj.name == marquee_selection_area.name:
		if ev is InputEventMouseButton and ev.is_released():
			obj.shape.size = Vector2(0,0)
			marquee_visible.size = Vector2(0,0)
			return
		var local_to_marquee_root = marquee_selection.get_local_mouse_position()
		obj.shape.size = abs(local_to_marquee_root)
		obj.position = Vector2(obj.shape.size.x / 2 * signi(local_to_marquee_root.x), obj.shape.size.y / 2 * signi(local_to_marquee_root.y))
		marquee_visible.size = obj.shape.size
		marquee_visible.position = Vector2(-marquee_visible.size.x / 2, -marquee_visible.size.y / 2)
		#marquee_visible.position = Vector2(marquee_visible.size.x / 2, marquee_visible.size.y / 2)
	else:
		obj.position = local_to_timeline_panel

func check_gui_mouse(ref):
	return ref.get_global_rect().has_point(get_viewport().get_mouse_position())
