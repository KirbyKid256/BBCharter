extends Node

var save_indicator: SaveIndicator
var error_notification: ErrorNotification
var confirm_menu: Panel
var file_dialog: FileDialog
var editor_menu: Control

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
