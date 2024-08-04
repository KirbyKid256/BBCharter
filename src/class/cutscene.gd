class_name Cutscene

enum {PRE,POST}

static var type: int

static var index: int = 0
static var current_panel: Dictionary

## Returns the absolute path of a cutscene at the given enum
static func path(path_enum: int = type):
	var path = Editor.project_path + "cutscene".path_join(["pre","post"][path_enum])
	
	if FileAccess.file_exists(path.path_join("script.cfg")):
		pass
	else:
		# Backwards compat for v2 Release mods
		if path_enum == PRE and FileAccess.file_exists(Editor.project_path.get_base_dir().get_base_dir() + "/_prologue/script.cfg"):
			path = Editor.project_path.get_base_dir().get_base_dir() + "/_prologue/"
		elif path_enum == POST and FileAccess.file_exists(Editor.project_path + "cutscene/script.cfg"):
			path = Editor.project_path + "cutscene/"
	
	return path

## Check if a script.cfg exists at the path specified
static func exists(path_enum: int) -> bool:
	var path: String = Editor.project_path + "cutscene".path_join(["pre","post"][path_enum])
	
	var config: ConfigFile = ConfigFile.new()
	if config.load(path.path_join("script.cfg")) == OK:
		Console.log({"message": "Found cutscene at path: %s" % path, "verbose": true})
		return true
	
	Console.log({"message": "Couldn't find cutscene", "verbose": true, "type": 2})
	return false

static func get_audio(track) -> AudioStreamOggVorbis:
	return AudioStreamOggVorbis.load_from_file(path().path_join("audio").path_join(track['path']))

static func get_image(image_path: String) -> ImageTexture:
	return Files.load_image(path().path_join("shots").path_join(image_path))
