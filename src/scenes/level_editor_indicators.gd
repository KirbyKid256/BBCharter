extends Node2D

@export var beat_indicator_prefab: PackedScene

@onready var beats: Node2D = Node2D.new()
@onready var half_beats: Node2D = Node2D.new()
@onready var third_beats: Node2D = Node2D.new()
@onready var quarter_beats: Node2D = Node2D.new()
@onready var sixth_beats: Node2D = Node2D.new()
@onready var eighth_beats: Node2D = Node2D.new()

enum {
	BEAT,
	HALF_BEAT,
	THIRD_BEAT,
	QUARTER_BEAT,
	SIXTH_BEAT,
	EIGHTH_BEAT
	}

func _ready():
	EventManager.editor_update_bpm.connect(create_indicators)
	
	add_child(beats)
	add_child(half_beats)
	add_child(third_beats)
	add_child(quarter_beats)
	add_child(sixth_beats)
	add_child(eighth_beats)
	
	if Editor.project_loaded: create_indicators()

# Create the indicators / Seperators in the timeline
func create_indicators():
	await get_tree().process_frame
	var float_beats = Math.secs_to_beat_dynamic(LevelEditor.song_length - Config.settings['song_offset'])
	
	Console.log({"message": 'Generating New Timeline Indicators'})
	for i in LevelEditor.song_beats_total:
		if beats.has_node(str(i)): continue
		var new_beat_indicator = beat_indicator_prefab.instantiate() as Node2D
		beats.add_child(new_beat_indicator)
		new_beat_indicator.setup(i, BEAT)
	
	for i in LevelEditor.song_beats_total * 2:
		if i % 2 == 0: continue
		if half_beats.has_node(str(i)): continue
		var new_beat_indicator = beat_indicator_prefab.instantiate() as Node2D
		half_beats.add_child(new_beat_indicator)
		new_beat_indicator.setup(i, HALF_BEAT)
	
	for i in (LevelEditor.song_beats_total + int(float_beats - int(float_beats) >= 1.0/3.0)) * 3:
		if i % 3 == 0: continue
		if third_beats.has_node(str(i)): continue
		var new_beat_indicator = beat_indicator_prefab.instantiate() as Node2D
		third_beats.add_child(new_beat_indicator)
		new_beat_indicator.setup(i, THIRD_BEAT)
	
	for i in (LevelEditor.song_beats_total + int(float_beats - int(float_beats) >= 0.75)) * 4:
		if i % 2 == 0: continue
		if quarter_beats.has_node(str(i)): continue
		var new_beat_indicator = beat_indicator_prefab.instantiate() as Node2D
		quarter_beats.add_child(new_beat_indicator)
		new_beat_indicator.setup(i, QUARTER_BEAT)
	
	for i in (LevelEditor.song_beats_total + int(float_beats - int(float_beats) >= 1.0/6.0)) * 6:
		if i % 3 == 0: continue
		if i % 2 == 0: continue
		if sixth_beats.has_node(str(i)): continue
		var new_beat_indicator = beat_indicator_prefab.instantiate() as Node2D
		sixth_beats.add_child(new_beat_indicator)
		new_beat_indicator.setup(i, SIXTH_BEAT)
	
	for i in (LevelEditor.song_beats_total + int(float_beats - int(float_beats) >= 0.125)) * 8:
		if i % 2 == 0: continue
		if eighth_beats.has_node(str(i)): continue
		var new_beat_indicator = beat_indicator_prefab.instantiate() as Node2D
		eighth_beats.add_child(new_beat_indicator)
		new_beat_indicator.setup(i, EIGHTH_BEAT)
	
	remove_indicators()

func remove_indicators():
	var song_end = -(LevelEditor.song_length - Config.settings['song_offset']) * LevelEditor.note_speed_mod
	
	Console.log({"message": 'Removing Old Indicators'})
	for i in range(beats.get_child_count() - 1, -1, -1):
		var beat = beats.get_child(i)
		if beat.position.x < song_end: Util.free_node(beat)
	
	for i in range(half_beats.get_child_count() - 1, -1, -1):
		var half = half_beats.get_child(i)
		if half.position.x < song_end: Util.free_node(half)
	
	for i in range(third_beats.get_child_count() - 1, -1, -1):
		var third = third_beats.get_child(i)
		if third.position.x < song_end: Util.free_node(third)
	
	for i in range(quarter_beats.get_child_count() - 1, -1, -1):
		var quarter = quarter_beats.get_child(i)
		if quarter.position.x < song_end: Util.free_node(quarter)
	
	for i in range(sixth_beats.get_child_count() - 1, -1, -1):
		var sixth = sixth_beats.get_child(i)
		if sixth.position.x < song_end: Util.free_node(sixth)
	
	for i in range(eighth_beats.get_child_count() - 1, -1, -1):
		var eighth = eighth_beats.get_child(i)
		if eighth.position.x <= song_end: Util.free_node(eighth)
