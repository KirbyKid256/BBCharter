extends Node2D

enum {
	BEAT,
	HALF_BEAT,
	THIRD_BEAT,
	QUARTER_BEAT,
	SIXTH_BEAT,
	EIGHTH_BEAT
	}

var indicator_index: int
var indicator_type: int

@onready var beat_line = $BeatLine
@onready var beat_num = $BeatNumber

func _ready():
	EventManager.editor_update_snapping.connect(_on_editor_update_snapping)
	EventManager.editor_update_notespeed.connect(update_position)
	EventManager.editor_update_bpm.connect(update_position)

func setup(i, type):
	indicator_index = i
	indicator_type = type
	name = str(i)
	
	# Set beat line points based on type
	var point_0 = beat_line.get("points")[0]
	var point_1 = beat_line.get("points")[1]
	beat_line.set("points", [point_0 * [1,0.8,0.7,0.6,0.5,0.4][type], point_1 * [1,0.8,0.7,0.6,0.5,0.4][type]] )
	
	# Show beat number
	beat_num.text = str(i)
	beat_num.set_visible(type == 0)
	
	# Set color
	beat_line.default_color = Color(1,1,1,[1,0.5,0.4,0.25,0.25,0.25][type])
	update_position()
	
	_on_editor_update_snapping(LevelEditor.snapping_index)

func update_position():
	position.x = -(Math.beat_to_secs_dynamic(float(indicator_index) / [1,2,3,4,6,8][indicator_type])) * LevelEditor.note_speed_mod

func _on_editor_update_snapping(snap_index: int):
	# 1/3rd and 1/6th beat are special cases, do not show them when even snaps are selected
	# Only show 1/2 beat when 1/6th is selected, no other even snaps
	if indicator_type == HALF_BEAT and snap_index == THIRD_BEAT:
		modulate = Color(1,1,1,0)
	elif indicator_type == QUARTER_BEAT and snap_index == SIXTH_BEAT:
		modulate = Color(1,1,1,0)
	elif indicator_type == THIRD_BEAT and (snap_index in [QUARTER_BEAT, EIGHTH_BEAT]):
		modulate = Color(1,1,1,0)
	elif indicator_type == SIXTH_BEAT and snap_index == EIGHTH_BEAT:
		modulate = Color(1,1,1,0)
	elif snap_index >= indicator_type:
		modulate = Color(1,1,1,1)
	else:
		modulate = Color(1,1,1,0)
