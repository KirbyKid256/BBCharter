extends Node

enum MODTYPE {LEGACY,DEMO,RELEASE,NONE = -1}

func _ready():
	Console.log({"message": "OS Name : %s" % OS.get_name()})
	Console.log({"message": "Screen Resolution : %s" % DisplayServer.screen_get_size()})

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
