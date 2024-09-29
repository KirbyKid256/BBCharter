class_name Editor

enum MODTYPE {LEGACY,DEMO,RELEASE,NONE = -1}

static var project_path: String
static var project_loaded: bool

static var controls_enabled: bool = true

static var level_changed: bool
static var saved_version: int = 1
static var cutscene_changed: bool

static func project_changed() -> bool:
	return level_changed or saved_version != Global.undo_redo.get_version() or cutscene_changed

static func save_project():
	LevelEditor.save_level()
	CutsceneEditor.save_scripts()

static func get_modtype(override_path: String = "") -> MODTYPE:
	var path: String
	if override_path != "":
		path = override_path
	else:
		path = Editor.project_path
	
	var config = ConfigFile.new()
	if config.load(path + "config/notes.cfg") == OK:
		var config_data: Dictionary = config.get_value("main", "data", {})
		if config_data.has("charts"):
			return MODTYPE.RELEASE
		elif config_data.has("chart"):
			return MODTYPE.DEMO
	elif FileAccess.file_exists(path + "chart.cfg"):
		return MODTYPE.LEGACY
	
	return MODTYPE.NONE

static func zip_directory(folder_path: String, dest_path: String):
	var packer = ZIPPacker.new()
	packer.open(dest_path)
	await dir_contents(packer, folder_path)
	packer.close()

static func dir_contents(packer: ZIPPacker, path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				dir_contents(packer, path + "/" + file_name)
			else:
				var write_path = path + "/" + file_name
				var relative_path = write_path.trim_prefix(Editor.project_path.get_base_dir().get_base_dir().get_base_dir() + "/")
				packer.start_file(relative_path)
				packer.write_file(FileAccess.get_file_as_bytes(write_path))
				packer.close_file()
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
