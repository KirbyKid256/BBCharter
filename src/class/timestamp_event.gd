class_name TSEvent
extends Node

var index: int = 0
var last_index: int = 0
var config_key: String = ""
var callback: Callable
var position_offset: float

func _process(_delta):
	if not Editor.level_loaded: return
	if Config.keyframes.get(config_key, []).is_empty(): return
	
	# Do math and pick the right asset based on time
	var items = Config.keyframes.get(config_key, []).filter(func(item): return LevelEditor.song_position_offset > item.get('timestamp', 0.0))
	index = items.size()
	if index != last_index:
		last_index = index
		callback.call(index-1)
