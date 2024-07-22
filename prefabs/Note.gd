extends Node2D


var hit: bool
var data: Dictionary
var beat: float
var horny: bool

var move_pos: bool
var mouse_pos: float
var mouse_pos_start: float
var mouse_pos_end: float
var clear_clipboard: bool
var selected_note: Node2D

func _ready():
	Events.update_notespeed.connect(update_position)
	Events.update_bpm.connect(update_position)
	Events.update_position.connect(update_position)

func setup(note_data, is_horny = false):
	data = note_data
	horny = is_horny
	move_pos = false
	clear_clipboard = false
	beat = Global.get_beat_at_time(data['timestamp'])
	update_visual()
	update_position()

func update_position():
	#print("pos update")
	data['timestamp'] = Global.get_time_at_beat(beat)
	position.x = -((data['timestamp'] - Global.offset) * Global.note_speed)
	update_visual()

func update_beat_and_position(time: float):
	#print("pos and beat update")
	beat = Global.get_beat_at_time(time)
	data['timestamp'] = time
	position.x = -((time - Global.offset) * Global.note_speed)
	Timeline.update_visuals()
	Timeline.update_map()

func _process(_delta):
	visible = global_position.x >= Global.note_culling_bounds.x and global_position.x < Global.note_culling_bounds.y
	$Selected.visible = Clipboard.selected_notes.has(self)
	if global_position.x >= 960 and !hit:
		#print("Hit?")
		Events.emit_signal('hit_note', data)
		hit = true
	elif global_position.x < 960 and hit:
		#print("Hit?2")
		Events.emit_signal('miss_note', data)
		hit = false
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if Global.snapping_allowed: mouse_pos = Global.get_mouse_timestamp_snapped()
		else: mouse_pos = Global.get_mouse_timestamp()
		if mouse_pos < 0: mouse_pos = 0
		
		if Clipboard.selected_notes.is_empty():return
		if Global.current_tool != Enums.TOOL.SELECT: return
		if move_pos:
			if selected_note != null:
				selected_note.update_beat_and_position(mouse_pos)
				Global.current_chart.sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
			else:
				move_pos = false

func update_visual():
	# print("update visual!")
	$Voice.visible = data.has('trigger_voice')
	$Visual.self_modulate = Global.note_colors[data['input_type']]
	$Glow.self_modulate = Global.note_colors[data['input_type']]
	$Label.add_theme_constant_override('outline_size', 8)
	
	if data['note_modifier'] == 3:
		if data['hold_end_timestamp'] != null:
			$Line2D.visible = true
			$Line2D.set_point_position(1, Vector2(-((data['hold_end_timestamp'] - data['timestamp'])*Global.note_speed), 0))
			if data['input_type'] == 1:
				$Line2D.default_color = Color(0.93,0.47,0.05,1)
			elif data['input_type'] == 2:
				$Line2D.default_color = Color(0.78,0.17,0.09,1)
			elif data['input_type'] == 3:
				$Line2D.default_color = Color(0.67,0.17,0.39,1)
			else: 
				$Line2D.default_color = Color(0.1,0.55,0.78,1)
				#$Line2D.set_point_position(1, Vector2(self.position.x + ((data['hold_end_timestamp']-data['timestamp'])- Global.offset),0))   #pos + (differnce bettween timestamp and end of hold note)
			#else: 
				#$Line2D.set_point_position(1, Vector2(((data['hold_end_timestamp'] + Global.offset)/ Global.note_speed),0))
			
			#var ed = Global.get_beat_at_time(data['hold_end_timestamp'])
			#var end_point = $Line2D.get_point_position(1)
			#end_point.x -= data['hold_end_timestamp']
			#$Line2D.set_point_position(1, end_point)
	else:
		$Line2D.visible = false
		$Line2D.set_point_position(0, Vector2((data['timestamp'] - Global.offset), 0))
		$Line2D.set_point_position(1, Vector2((data['timestamp'] - Global.offset), 0))
	
	if data['note_modifier'] == 1:
		$Handsfree.show()
		$Handsfree/Handsfreeinner.self_modulate = Global.note_colors[data['input_type']]
		$Handsfree/Handsfreeinner.visible = !($Voice.visible)
		$Voice.self_modulate = Global.note_colors[data['input_type']]
	else:
		$Handsfree.hide()
		$Voice.self_modulate = Color.ANTIQUE_WHITE
	$Ghost.visible = data['note_modifier'] == 2
	
	if data.has('horny') and data['horny'].has('required') and data['horny']['required'] >= 0:
		horny = true
		$Label.text = str(data['horny']['required'])
		$Voice.scale = Vector2(0.667,0.667)
		$Handsfree/Handsfreeinner.scale = Vector2(0.5,0.5)
		if data.has('trigger_voice'):
			if data['note_modifier'] != 1:
				$Label.add_theme_color_override('font_color', Color.WHITE)
				$Label.add_theme_color_override('font_outline_color', $Visual.self_modulate)
			else:
				$Label.add_theme_color_override('font_color', $Visual.self_modulate)
				$Label.add_theme_color_override('font_outline_color', Color.WHITE)
		else:
			$Label.remove_theme_color_override('font_color')
			$Label.add_theme_color_override('font_outline_color', $Visual.self_modulate)
	else:
		$Label.text = ''
		$Voice.scale = Vector2(0.444,0.444)
		$Handsfree/Handsfreeinner.scale = Vector2(0.2,0.2)
	
	$Glow.visible = horny


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if Global.current_tool == Enums.TOOL.SELECT:
						if !Clipboard.selected_notes.has(self):
							selected_note = self
							mouse_pos_start = self['data']['timestamp']
							if Clipboard.selected_notes.size() >= 1:
								Clipboard.clear_clipboard()
							if !Clipboard.selected_notes.has(selected_note):
								Clipboard.selected_notes.append(selected_note)
							update_visual()
					else:
						Global.project_saved = false
					if Global.current_tool == Enums.TOOL.VOICE:
						toggle_voice_trigger()
					if Global.current_tool == Enums.TOOL.HORNY:
						horny_add()
					if Global.current_tool == Enums.TOOL.MODIFY:
						modify_cycle(1)
				MOUSE_BUTTON_RIGHT:
					Global.project_saved = false
					if Global.current_tool == Enums.TOOL.SELECT or Global.current_tool == Enums.TOOL.MARQUEE:
						if Clipboard.selected_notes.size() > 1:
							for x in Clipboard.selected_notes:
								Timeline.delete_note(x, Global.current_chart.find(x.data))
						else:
							Timeline.delete_note(self, Global.current_chart.find(data))
					if Global.current_tool == Enums.TOOL.HORNY:
						horny_remove()
					if Global.current_tool == Enums.TOOL.MODIFY:
						modify_cycle(-1)
		else:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if Global.current_tool == Enums.TOOL.SELECT:
						mouse_pos_end = mouse_pos
						for note in Timeline.note_container.get_children(): if note != selected_note: if snappedf(note['data']['timestamp'], 0.001) == snappedf(selected_note['data']['timestamp'], 0.001):
							if Global.replacing_allowed:
								Timeline.delete_note(note, Global.current_chart.find(note['data']))
							else:
								print('[Note] Note already exists at %s' % [snappedf(mouse_pos_end, 0.001)])
								selected_note.update_beat_and_position(mouse_pos_start)
								selected_note.move_pos = false
								break
						Global.current_chart.sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
						update_position()
						if mouse_pos_start != selected_note['data']['timestamp']: 
							Global.project_saved = false
						mouse_pos_start = 0
						mouse_pos_end = 0 
						move_pos = false
						print("move pos false")

func horny_add():
	Events.emit_signal('tool_used_before', data)
	
	if !data.has('horny') or !data['horny'].has('required'):
		horny = true
		data['horny'] = {'required': 0}
	else:
		if Global.current_chart.find(data) + data['horny']['required'] + 1 > Timeline.note_container.get_child_count(): return
		
		data['horny']['required'] += 1
		var notes: Array = Timeline.note_container.get_children().filter(func(x): return x.data['timestamp'] > data['timestamp'])
		if data['horny']['required'] > 1:
			for i in data['horny']['required']:
				var index = clampi(i - 1, 0, data['horny']['required'])
				notes[index].horny = true
				notes[index].update_visual()
	
	update_visual()
	Events.emit_signal('tool_used_after', data)

func horny_remove():
	Events.emit_signal('tool_used_before', data)
	
	if data.has('horny') and data['horny'].has('required'):
		if data['horny']['required'] == 0:
			horny = false
			data.erase('horny')
		else:
			data['horny']['required'] -= 1
			var notes: Array = Timeline.note_container.get_children().filter(func(x): return x.data['timestamp'] > data['timestamp'])
			var index = data['horny']['required'] - 1
			notes[index].horny = false
			notes[index].update_visual()
	
	update_visual()
	Events.emit_signal('tool_used_after', data)

func toggle_voice_trigger():
	Events.emit_signal('tool_used_before', data)
	
	if data.has('trigger_voice'):
		data.erase('trigger_voice')
	else:
		data['trigger_voice'] = true
	
	update_visual()
	Events.emit_signal('tool_used_after', data)

func modify_cycle(i):
	Events.emit_signal('tool_used_before', data)
	data['note_modifier'] = wrapi(data['note_modifier'] + i, 0, 3)
	update_visual()
	Events.emit_signal('tool_used_after', data)

func _on_mouse_exited():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Global.current_tool == Enums.TOOL.SELECT: move_pos = true
