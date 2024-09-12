extends Node2D
class_name NoteSelector

@onready var selection_area: Area2D = $SelectionArea
@onready var selection_shape: CollisionShape2D = $SelectionArea/SelectionShape
@onready var note_track: Node2D = $'../NoteTimeline/TimelineRoot/Notes'

var dragging_area: bool
var drag_start_pos: Vector2
var drag_end_pos: Vector2

func _input(event: InputEvent):
	if LevelEditor.current_tool != LevelEditor.TOOL.POINT:
		dragging_area = false
		return
	
	# Selected Note Handling
	if event.is_action_pressed("ui_delete"):
		if not LevelEditor.selected_notes.is_empty(): group_delete_notes()
	
	# Note Selection
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if event.position.y < 744: return
			dragging_area = true
			drag_start_pos = event.position
		elif dragging_area:
			dragging_area = false
			drag_end_pos = event.position
			queue_redraw()
			get_notes_in_selection()
	
	if event is InputEventMouseMotion and dragging_area:
		queue_redraw()

func _draw():
	if dragging_area:
		draw_rect(Rect2(drag_start_pos, get_global_mouse_position() - drag_start_pos), Color(0,1,0.6), false, 2.0)

func get_notes_in_selection():
	var distance = (drag_end_pos - drag_start_pos)
	selection_shape.shape.size = abs(distance)
	selection_area.position = drag_start_pos + (selection_shape.shape.size / 2)
	
	if distance.x < 0: selection_area.position.x -= selection_shape.shape.size.x
	if distance.y < 0: selection_area.position.y -= selection_shape.shape.size.y
	
	# Select notes
	await get_tree().create_timer(0.1).timeout
	
	var area_notes = selection_area.get_overlapping_areas().map(func(area): return area.get_parent())
	
	if Input.is_action_pressed("ui_shift"): 
		for new_note in area_notes:
			if LevelEditor.selected_notes.has(new_note):
				LevelEditor.selected_notes.erase(new_note)
				new_note.selected = false
				new_note.check_selected()
			else:
				LevelEditor.selected_notes.append(new_note) # append notes to array
	else:
		LevelEditor.selected_notes = area_notes # Replace notes
	
	LevelEditor.selected_notes.sort_custom(func(a, b): return a.data['timestamp'] < b.data['timestamp'])
	select_notes()

func select_notes():
	# Clear other selected notes, if not holding shift
	if not Input.is_action_pressed("ui_shift"):
		for note: EditorNote in note_track.get_children():
			if note.selected: 
				note.selected = false
				note.check_selected()
	
	# Highlight selected notes
	for note: EditorNote in LevelEditor.selected_notes:
		note.selected = true
		note.check_selected()

func group_delete_notes():
	for i in range(LevelEditor.selected_notes.size()-1, -1, -1):
		LevelEditor.selected_notes[i].delete_note()
	LevelEditor.selected_notes.clear()

func deselect_notes():
	for note: EditorNote in LevelEditor.selected_notes:
		note.selected = false
		note.check_selected()
	LevelEditor.selected_notes.clear()
