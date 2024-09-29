class_name LevelEditor

enum TOOL {POINT,MODIFY,HOLD,VOICE}
enum NOTETYPE {
	NORMAL, # 0
	AUTO, # 1
	GHOST, # 2
	HOLD, # 3
	BOMB, # 4
	HORNY # 5
}

# Menu
enum IMAGE {ANIMATION,EFFECT,BACKGROUND}
enum AUDIO {ONESHOT,LOOP,BANK,MUSIC,FINAL,HORNY}
enum VIDEO {PREVIEW,FINAL}

# General
static var editor_asset_cache: Array
static var difficulty_index: int = -1
static var current_tool: int

# Snapping
static var snapping_allowed = true
static var snapping_factor: int = 1
static var snapping_index: int

# Music
static var song_position_raw: float
static var song_position_offset: float
static var song_beats_total: int
static var song_beats_per_second: float
static var song_length: float

# Notes
static var note_speed_mod: float = 350
static var selected_notes: Array

#region Song Functions
static func calculate_song_info(stream: AudioStream):
	if stream == null: return # Dont run if no audio present
	
	song_length = stream.get_length()
	song_beats_per_second = float(60.0/Config.keyframes['modifiers'][0]['bpm'])
	song_beats_total = ceil(Math.secs_to_beat_dynamic(song_length - Config.settings['song_offset']))

static func get_timestamp(snap: bool = snapping_allowed) -> float:
	var song_length_offset = snappedf(song_length - Config.settings['song_offset'], 0.001)
	var time = Math.beat_to_secs_dynamic((snappedf(Math.secs_to_beat_dynamic(song_position_offset), 1.0 / snapping_factor)
	if snap else Math.secs_to_beat_dynamic(song_position_offset)))
	
	return song_length_offset if time > song_length_offset\
	else -Config.settings['song_offset'] if time < -Config.settings['song_offset']\
	else snappedf(time, 0.001)

static func get_mouse_timestamp(mouse_pos, snap: bool = snapping_allowed) -> float:
	mouse_pos -= 960
	# Need to grab mouse pos calculations externally
	var song_length_offset = snappedf(song_length - Config.settings['song_offset'], 0.001)
	var time = ((song_position_offset * note_speed_mod) - mouse_pos) / note_speed_mod
	time = Math.beat_to_secs_dynamic((snappedf(Math.secs_to_beat_dynamic(time), 1.0 / snapping_factor)
	if snap else Math.secs_to_beat_dynamic(time)))
	
	return song_length_offset if time > song_length_offset\
	else -Config.settings['song_offset'] if time < -Config.settings['song_offset']\
	else snappedf(time, 0.001)
#endregion

#region Asset Cache
static func get_asset_cache() -> Array:
	var asset_config = ConfigFile.new()
	
	if asset_config.load(Editor.project_path + "editor_cache.cfg") == OK:
		return asset_config.get_value("main","data", [])
	return []

# Add an asset to the cache
static func append_asset_cache(cache_data: Dictionary) -> void:
	editor_asset_cache = get_asset_cache()
	
	# Check if asset exists
	if editor_asset_cache.has(cache_data):
		Console.log({"message": "Asset already exists in cache...", "type": 1})
		return
	
	editor_asset_cache.append(cache_data)
	var asset_config: ConfigFile = ConfigFile.new()
	asset_config.set_value("main","data",editor_asset_cache)
	asset_config.save(Editor.project_path + "editor_cache.cfg")

# Remove an asset from the cache
static func remove_asset_cache(cache_data: Dictionary) -> void:
	editor_asset_cache = get_asset_cache()
	
	# Check if asset exists
	if not editor_asset_cache.has(cache_data):
		Console.log({"message": "Asset does not exist in cache...", "type": 1})
		return
	
	editor_asset_cache.remove_at(editor_asset_cache.find(cache_data))
	var asset_config: ConfigFile = ConfigFile.new()
	asset_config.set_value("main","data",editor_asset_cache)
	asset_config.save(Editor.project_path + "editor_cache.cfg")

# Replace an asset in the cache
static func replace_asset_cache(old_data: Dictionary, new_data: Dictionary) -> void:
	editor_asset_cache = get_asset_cache()
	
	# Check if asset exists
	if editor_asset_cache.has(old_data):
		var index: int = editor_asset_cache.find(old_data)
		editor_asset_cache.remove_at(index)
		editor_asset_cache.insert(index, new_data)
	else:
		Console.log({"message": "Asset does not exist in cache...", "type": 1})
		return
	
	var asset_config: ConfigFile = ConfigFile.new()
	asset_config.set_value("main","data",editor_asset_cache)
	asset_config.save(Editor.project_path + "editor_cache.cfg")
#endregion

# Place all keyframes found in config
static func place_init_keyframes(key: String, root_node: Node2D, prefab: PackedScene):
	for keyframe_data in Config.keyframes.get(key, []):
		if Editor.project_loaded:
			root_node.add_keyframe(keyframe_data)
		else:
			var new_keyframe = prefab.instantiate() as Node2D
			root_node.add_child(new_keyframe)
			new_keyframe.setup(keyframe_data)

# Create a new keyframe from an asset
static func create_new_keyframe(key: String, data: Dictionary, timestamp: float) -> bool:
	# Check if keyframe already exists there
	if not Config.keyframes[key].filter(LevelEditor.check_keyframe_exists.bind(timestamp)).is_empty():
		Console.log({"message": "Keyframe already exists...", "type": 1}); return false
	
	Console.log({"message": "Creating new keyframe..."})
	Config.keyframes[key].append(data)
	Config.keyframes[key].sort_custom(func(a, b): return a['timestamp'] < b['timestamp'])
	return true

# Check if there's already a keyframe at the desired time
static func check_keyframe_exists(keyframe: Dictionary, timestamp: float):
	return snappedf(keyframe.timestamp, 0.001) == snappedf(timestamp, 0.001)

static func add_single_keyframe(data: Dictionary, root_node: Node2D, prefab: PackedScene):
	var new_keyframe = prefab.instantiate() as Node2D
	root_node.add_child(new_keyframe)
	new_keyframe.setup(data)

static func save_level():
	Console.log({"message": "Saving Project"})
	
	Config.save_config_data("asset.cfg", Config.asset)
	Config.save_config_data("keyframes.cfg", Config.keyframes)
	Config.save_config_data("meta.cfg", Config.meta)
	Config.save_config_data("notes.cfg", Config.notes)
	Config.save_config_data("settings.cfg", Config.settings)
	
	if not Config.mod.is_empty():
		Config.save_config_data("mod.cfg", Config.mod)
	
	if not Config.act.is_empty():
		var config: ConfigFile = ConfigFile.new()
		config.set_value('main', 'data', Config.act)
		config.save(Editor.project_path.get_base_dir().get_base_dir().path_join("act.cfg"))
	
	Editor.saved_version = Global.undo_redo.get_version()
	Editor.level_changed = false
