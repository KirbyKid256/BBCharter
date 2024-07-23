extends Node2D

@export var editor_shutter_prefab: PackedScene

func load_keyframes():
	LevelEditor.place_init_keyframes("shutter", self, editor_shutter_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func create_shutter():
	var timestamp = LevelEditor.get_timestamp()
	var new_shutter_data = {'timestamp': timestamp}
	
	Console.log({"message": "Creating Shutter at %s" % timestamp})
	LevelEditor.create_new_keyframe("shutter", new_shutter_data, timestamp)
	LevelEditor.add_single_keyframe(new_shutter_data, self, editor_shutter_prefab)
