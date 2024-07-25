extends Node2D

@export var editor_keyframe_prefab: PackedScene

@onready var character = $"../../../../Preview/Character"

func _ready():
	EventManager.editor_try_add_animation.connect(create_keyframe)

func load_keyframes():
	LevelEditor.place_init_keyframes("loops", self, editor_keyframe_prefab)

func _process(_delta):
	position.x = (LevelEditor.song_position_offset * LevelEditor.note_speed_mod) + 960

func create_keyframe(keyframe_data: Dictionary):
	var timestamp = LevelEditor.get_timestamp()
	var new_keyframe_data: Dictionary = {
		"animations": {"normal": keyframe_data["sprite_sheet"]},
		"sheet_data": keyframe_data["sheet_data"],
		"timestamp": timestamp
	}
	
	if keyframe_data.has("scale_multiplier"):
		new_keyframe_data.merge({"scale_multiplier": keyframe_data["scale_multiplier"]})
	
	if LevelEditor.create_new_keyframe("loops", new_keyframe_data, timestamp):
		LevelEditor.add_single_keyframe(new_keyframe_data, self, editor_keyframe_prefab)
		if LevelEditor.song_position_offset <= Config.keyframes['loops'][0]['timestamp']:
			character.change_animation(Config.keyframes["loops"].find(new_keyframe_data))
		Editor.project_changed = true
