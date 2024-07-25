extends Node

enum MODTYPE {LEGACY,DEMO,RELEASE,NONE = -1}

func _ready():
	Console.log({"message": "OS Name : %s" % OS.get_name()})
	Console.log({"message": "Screen Resolution : %s" % DisplayServer.screen_get_size()})

func get_executable_path() -> String:
	if OS.is_debug_build():
		return ProjectSettings.globalize_path("res://")
	else:
		var app = OS.get_executable_path().get_slice("/", OS.get_executable_path().get_slice_count("/")-4)
		if OS.get_name() == "macOS" and OS.get_executable_path().contains(app + "/Contents/MacOS"):
			return OS.get_executable_path().get_base_dir().get_base_dir().get_base_dir().get_base_dir()
		return OS.get_executable_path().get_base_dir()

func get_modtype(override_path: String = "") -> MODTYPE:
	var path: String
	if override_path != "":
		path = override_path
	else:
		path = Editor.level_path
	
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
