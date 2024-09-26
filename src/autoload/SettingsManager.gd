extends Node

var data: Dictionary
var defaults: Array = [
	# Video Settings
	{"key":"volume", "default": 0.5},
	{"key":"screen", "default": 0}, 
	{"key":"resolution", "default": 3},
]

var current_screen
var available_resolutions: Array = [
	Vector2i(960,540), 
	Vector2i(1280,720), 
	Vector2i(1600,900), 
	Vector2i(1920,1080), 
	Vector2i(2560,1440), 
	Vector2i(3840,2160)
]

func validate_settings():
	for ref in defaults: if not data.has(ref.key): data[ref.key] = ref.default

func save():
	var config: ConfigFile = ConfigFile.new()
	config.set_value("settings", "data", SettingsManager.data)
	config.save("user://settings.ini")

func load():
	Console.log({"message": "Loading User Settings..."})
	var settings_config: ConfigFile = ConfigFile.new()
	if settings_config.load("user://settings.ini") == OK:
		SettingsManager.data = settings_config.get_value("settings", "data", {})
	
	validate_settings()
	save()

func clear_settings():
	var config: ConfigFile = ConfigFile.new()
	config.set_value("settings", "data", {})
	data = config.get_value("settings", "data")
	
	await validate_settings()
	config.save("user://settings.ini")

func set_display_mode():
	var state = data.get("screen", 0)
	match state:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	
	save()

func get_available_resolutions() -> Array:
	return available_resolutions.filter(func(resolution): return resolution <= DisplayServer.screen_get_size(current_screen))

func set_resolution():
	var res_array: Array = []
	
	current_screen = DisplayServer.get_primary_screen()
	res_array = get_available_resolutions()
	
	var res_index = clampi(SettingsManager.data.get('resolution', 3), 0, res_array.size())
	var new_resolution = res_array[res_index]
	if new_resolution > DisplayServer.screen_get_size(current_screen): res_index = 0
	data.resolution = res_index
	save()
	
	var window_size = DisplayServer.window_get_size()/2
	DisplayServer.window_set_size(new_resolution)
	DisplayServer.window_set_position(get_window().position - (DisplayServer.window_get_size()/2 - window_size))
	DisplayServer.window_set_current_screen(current_screen)
