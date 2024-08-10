class_name Config

static var asset: Dictionary
static var keyframes: Dictionary
static var meta: Dictionary
static var notes: Dictionary
static var settings: Dictionary

static var act: Dictionary
static var mod: Dictionary

## Stores Data into the static Beat Banger Config vars
static func store_config_data() -> bool:
	Console.log({"message": "Loading Level Configuration Files..."})
	if Editor.get_modtype() == Editor.MODTYPE.NONE: return false
	
	load_chart()
	
	for key: Dictionary in [asset, keyframes, meta, notes, settings]:
		if key.is_empty(): return false
	return true

## Loads Beat Banger config file 
static func load_config_data(path: String, level_path_override: String = Editor.project_path) -> Dictionary:
	var config: ConfigFile = ConfigFile.new()
	if config.load(level_path_override.path_join("config").path_join(path)) == OK:
		Console.log({"message": "Successfully Loaded: %s" % path, "verbose": true})
		return config.get_value("main", "data", {})
	else:
		Console.log({"message": "Could Not Load: %s" % path, "type": 2})
		return {}

## Saves Beat Banger config file 
static func save_config_data(path: String, data: Dictionary):
	var config: ConfigFile = ConfigFile.new()
	config.set_value('main', 'data', data)
	config.save(Editor.project_path.path_join("config").path_join(path))

## Check to see if there is a valid ID
static func validate_ids():
	Console.log({"message": "Validating IDs"})
	
	if not meta.has("level_id"): meta["level_id"] = create_new_id(meta, meta.get("level_name"))
	if not act.is_empty() and not act.has("act_id"): act["act_id"] = create_new_id(act, act.get("act_name"))

## Create a new ID
static func create_new_id(dict: Dictionary, hash_string: String) -> String:
	Console.log({"message": "Creating new ID..."})
	var curtime = Time.get_unix_time_from_system()
	var new_hash = hash_string + str(curtime)
	return new_hash.md5_text()

## Loads Legacy Beat Banger config file 
static func load_legacy_data(path: String, section: String = "") -> Dictionary:
	var config = ConfigFile.new()
	if section == "": section = "META" if path.get_file() == "meta.cfg" else "EASY"
	
	if config.load(path) == OK:
		var config_data = {}
		var keys = config.get_section_keys(section)
		for key in keys: config_data[key] = config.get_value(section, key)
		if not config_data.is_empty():
			Console.log({"message": "Successfully Loaded: %s" % path, "verbose": true})
			return config_data
		else:
			Console.log({"message": "Empty: %s" % path, "verbose": true, "type": 2})
			return {}
	else:
		Console.log({"message": "Could Not Load: %s" % path, "verbose": true, "type": 2})
		return {}

## Remaps chart for optimized playing
static func load_chart(path: String = Editor.project_path):
	var mod_type = Editor.get_modtype(path)
	match mod_type:
		Editor.MODTYPE.LEGACY:
			var chart: Dictionary = load_legacy_data(path + "chart.cfg")
			asset = {}; keyframes = {}; meta = {}; notes = {}; settings = {}
			
			# Asset
			asset["song_path"] = chart.get("song_path", "")
			if chart.has("last_transition"): asset["final_audio"] = chart["last_transition"]["climax_sound"]
			
			# Keyframes
			keyframes["background"] = []
			keyframes["effects"] = []
			keyframes["loops"] = []
			keyframes["sound_loop"] = []
			keyframes["sound_oneshot"] = []
			keyframes["voice_bank"] = []
			keyframes["modifiers"] = [{"bpm": chart.get_or_add("bpm", 120.0), "timestamp": 0.0}]
			
			var last_beat = chart["last_beat"][0] if chart.has("last_beat") else chart["transitions"].keys()[chart["transitions"].size()-1]
			for beat in [0] + chart["transitions"].keys() + chart.get("last_beat", []):
				var cum = beat == last_beat
				var transition = chart["initial_data"] if beat == 0 else chart["last_transition"] if cum and chart.has("last_beat") else chart["transitions"][beat]
				var timestamp = Math.beats_to_secs(beat, chart["bpm"]*2) if beat > 0 else 0.0
				var legacy_sheet = {"h": 3, "v": 2, "total": 6}
				
				var loop = {
					"animations": {"normal": transition["animation"]},
					"sheet_data": legacy_sheet,
					"timestamp": timestamp
				}
				
				loop["scale_multiplier"] = 0.9
				keyframes["loops"].append(loop)
				
				if transition.has("sound_fx"):
					keyframes["sound_loop"].append({
						"path": transition["sound_fx"],
						"timestamp": timestamp
					})
				
				if beat > 0:
					if transition["effects"].is_valid_filename():
						var effect = {
							"duration": (2.0 / 0.5 if cum else 1.0 / 1.2) * chart["loop_speed"],
							"path": transition["effects"],
							"sheet_data": {"h": 6, "v": 4, "total": 24} if cum else legacy_sheet,
							"timestamp": timestamp
						}
						if cum: effect["keep"] = true
						keyframes["effects"].append(effect)
					
					if transition.has("transition_sound"):
						keyframes["sound_oneshot"].append({
							"path": transition["transition_sound"],
							"timestamp": timestamp
						})
			
			# Meta
			meta["level_index"] = load_legacy_data(path + "meta.cfg").get("level_index", 0)
			meta["level_name"] = load_legacy_data(path + "meta.cfg").get("mod_title", chart.get_or_add("name", "Legacy Mod"))
			meta["level_id"] = chart.get("level_id", create_new_id(meta, chart["name"]))
			
			# Notes
			notes["charts"] = [{
				"name": "Normal",
				"notes": load_legacy_notes(chart),
				"rating": 0
				}]
			
			# Settings
			settings["song_offset"] = -chart.get("note_offset", 0.0)
			settings["post_song_delay"] = chart.get("post_song_delay", 5.0)
			
			Config.convert()
		Editor.MODTYPE.DEMO:
			asset = load_config_data("asset.cfg")
			keyframes = load_config_data("keyframes.cfg")
			meta = load_config_data("meta.cfg")
			notes = load_config_data("notes.cfg")
			settings = load_config_data("settings.cfg")
			mod = load_config_data("mod.cfg")
			
			# Asset
			asset.erase("level_start_sound")
			
			# Keyframes
			for key in keyframes.keys():
				if keyframes[key].is_empty(): continue
				if key == "effects":
					for dict in keyframes[key]: if dict['beat'] <= 0:
						keyframes[key].remove_at(keyframes[key].find(dict))
					
					for dict in keyframes[key]:
						dict["duration"] = dict["playback_speed"]
						dict.erase("playback_speed")
						dict["timestamp"] = Math.beats_to_secs(dict["beat"], settings["bpm"]*2)
						dict.erase("beat")
				else:
					for dict in keyframes[key]:
						dict['timestamp'] = Math.beats_to_secs(dict["beat"], settings["bpm"]*2)
						dict.erase("beat")
			keyframes["modifiers"] = [{"bpm": settings["bpm"], "timestamp": 0.0}]
			
			# Notes
			notes["charts"] = [{
				"name": "Normal",
				"notes": load_demo_notes(notes["chart"]),
				"rating": 0
				}]
			notes.erase("chart")
			notes.erase("colors")
			
			# Settings
			settings["song_offset"] = -settings["note_offset"]
			settings.erase("bpm")
			settings.erase("note_beat_delay")
			settings.erase("song_length_in_beats")
			
			Config.convert()
		Editor.MODTYPE.RELEASE:
			asset = load_config_data("asset.cfg")
			keyframes = load_config_data("keyframes.cfg")
			meta = load_config_data("meta.cfg")
			notes = load_config_data("notes.cfg")
			settings = load_config_data("settings.cfg")
			mod = load_config_data("mod.cfg")
			
			var act_path: String = path.get_base_dir().get_base_dir().path_join("act.cfg")
			var config: ConfigFile = ConfigFile.new()
			if config.load(act_path) == OK: Config.act = config.get_value("main", "data")
			
			notes['charts'].sort_custom(func(a, b): return a.get('rating', 0) < b.get('rating', 0))
		_:
			Console.log({"message": "Invalid Level Path: %s" % path, "verbose": true, "type": 2})

static func load_demo_notes(demo_chart: Array):
	var new_notes: Array = []
	for note in demo_chart:
		var new_note = {
			"input_type": note["input_type"],
			"note_modifier": LevelEditor.NOTETYPE.GHOST if note["ghost"] else LevelEditor.NOTETYPE.NORMAL,
			"timestamp": Math.beats_to_secs(note["beat"], settings["bpm"]*2)
		}
		if note.has("horny"): new_note["horny"] = note["horny"]
		new_notes.append(new_note)
	return new_notes

static func load_legacy_notes(legacy_chart: Dictionary):
	var new_notes: Array = []
	
	var init_note = legacy_chart['initial_data']['note_type'] if legacy_chart.has('initial_data') else 0
	var no_spawn = legacy_chart['no_spawn']
	var half_spawn = legacy_chart['half_spawn']
	var quarter_spawn = legacy_chart['quarter_spawn']
	var eighth_spawn = legacy_chart['eighth_spawn']
	var last_beat = (legacy_chart['last_beat'][0] if legacy_chart.has('last_beat')
	else legacy_chart['lastBeat'][0] if legacy_chart['lastBeat'][0] < legacy_chart['transitions'].keys()[legacy_chart['transitions'].size()-1]
	else legacy_chart['transitions'].keys()[legacy_chart['transitions'].size()-1])
	
	var input_type = init_note + 1
	var beat = 4 if input_type == 0 else 2 if input_type == 1 else 1
	
	for i in last_beat:
		if i > 0:
			if half_spawn.has(i):
				input_type = 0
				beat = 4
			elif quarter_spawn.has(i):
				input_type = 1
				beat = 2
			elif eighth_spawn.has(i):
				input_type = 2
				beat = 1
		else:
			input_type = init_note - 1
			match init_note:
				1: beat = 4
				2: beat = 2
				3: beat = 1
		
		if no_spawn.has(i) and i > 0 or input_type == -1:
			input_type = -1
			continue
		
		if i % beat == 0:
			new_notes.append({
				"input_type": input_type,
				"note_modifier": LevelEditor.NOTETYPE.NORMAL,
				"timestamp": Math.beats_to_secs(i, legacy_chart["bpm"]*2)
			})
	
	return new_notes

## Saves current chart as a Release chart, use after load_chart()
static func convert(path: String = Editor.project_path):
	var mod_type = Editor.get_modtype(path)
	if mod_type == Editor.MODTYPE.RELEASE: return Console.log({"message": "Chart is already in RELEASE format", "verbose": true, "type": 1})
	
	if mod_type == Editor.MODTYPE.LEGACY:
		var path_backup: String = path.get_base_dir() + " backup"
		DirAccess.rename_absolute(path, path_backup)
		DirAccess.make_dir_absolute(path)
		
		var cover: Image = preload("res://assets/images/placeholder_legacy_album_cover.png").get_image()
		cover.save_png(path + "thumb.png")
		
		var act_config = ConfigFile.new()
		act = {
			"act_description": "Converted From Legacy",
			"act_index": 0,
			"act_name": load_legacy_data(path_backup + "/chart.cfg").get("name", "Legacy Mod"),
			"act_legacy": true
		}
		act_config.set_value("main", "data", act); act_config.save(path.path_join("act.cfg"))
		
		path = path.path_join(act.act_name)
		DirAccess.make_dir_absolute(path)
		
		if FileAccess.file_exists(path_backup + "/thumb.png"):
			DirAccess.copy_absolute(path_backup + "/thumb.png", path + "/thumb.png")
		else:
			var thumb: Image = preload("res://assets/images/placeholder_legacy_album_cover.png").get_image()
			thumb.save_png(path + "/thumb.png")
		
		if FileAccess.file_exists(path_backup + "/splash.png"):
			DirAccess.copy_absolute(path_backup + "/splash.png", path + "/splash.png")
		else:
			var splash: Image = preload("res://assets/images/placeholder_splash.png").get_image()
			splash.save_png(path + "/splash.png")
		
		DirAccess.make_dir_absolute(path + "/audio")
		DirAccess.make_dir_absolute(path + "/config")
		DirAccess.make_dir_absolute(path + "/images")
		
		for file in DirAccess.get_files_at(path_backup + "/anims"):
			DirAccess.copy_absolute(path_backup + "/anims/%s" % file, path + "/images/%s" % file)
		for file in DirAccess.get_files_at(path_backup + "/anims/fx"):
			DirAccess.copy_absolute(path_backup + "/anims/fx/%s" % file, path + "/images/%s" % file)
		
		for folder in DirAccess.get_directories_at(path_backup + "/voice"):
			for file in DirAccess.get_files_at(path_backup + "/voice/%s" % folder):
				DirAccess.copy_absolute(path_backup + "/voice/%s/%s" % [folder, file], path + "/audio/%s" % file)
		
		for file in DirAccess.get_files_at(path_backup + "/sfx"):
			DirAccess.copy_absolute(path_backup + "/sfx/%s" % file, path + "/audio/%s" % file)
		
		for file in DirAccess.get_files_at(path_backup + "/songs"):
			DirAccess.copy_absolute(path_backup + "/songs/%s" % file, path + "/audio/%s" % file)
		
		for file in DirAccess.get_files_at(path_backup + "/textures"):
			DirAccess.copy_absolute(path_backup + "/textures/%s" % file, path + "/images/%s" % file)
		
		path = path + "/"
		Editor.project_path = path
		Global.file_dialog.current_dir = path
	
	for key: String in ["loops", "effects", "background", "voice_bank"]:
		for data: Dictionary in keyframes[key]:
			if data.is_empty(): continue
			
			data = data.duplicate(true)
			data.erase("timestamp")
			
			if key == "loops":
				data["sprite_sheet"] = data.animations.normal
				data.erase("animations")
			else:
				data["audio_path" if key == "voice_bank" else "sprite_sheet"] = data.path
				data.erase("path")
			LevelEditor.append_asset_cache(data)
	
	var config = ConfigFile.new()
	config.set_value("main", "data", notes); config.save(path + "config/notes.cfg")
	config.set_value("main", "data", asset); config.save(path + "config/asset.cfg")
	config.set_value("main", "data", keyframes); config.save(path + "config/keyframes.cfg")
	config.set_value("main", "data", meta); config.save(path + "config/meta.cfg")
	config.set_value("main", "data", settings); config.save(path + "config/settings.cfg")
	
	Console.log({"message": "Converted %s chart to RELEASE" % Editor.MODTYPE.keys()[mod_type], "verbose": true})
