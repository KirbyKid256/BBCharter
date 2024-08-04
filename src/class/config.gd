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

## Check to see if the ACT has a valid act_id
static func validate_ids():
	Console.log({"message": "Validating IDs"})
	
	if not meta.has("level_id"): meta["level_id"] = create_new_id(meta, meta.get("level_name"))
	if not act.is_empty() and not act.has("act_id"): act["act_id"] = create_new_id(act, act.get("act_name"))

## Create a new act_id in the speicified ACT
static func create_new_id(dict: Dictionary, hash_string: String) -> String:
	Console.log({"message": "Creating new ID..."})
	var curtime = Time.get_unix_time_from_system()
	var new_hash = hash_string + str(curtime)
	return new_hash.md5_text()

## Remaps chart for optimized playing
static func load_chart(path: String = Editor.project_path):
	var mod_type = Editor.get_modtype(path)
	match mod_type:
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
