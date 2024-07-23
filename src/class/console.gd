class_name Console

static var log_types: Array = [
	{"name": "INFO", "color": "green"},
	{"name": "WARN", "color": "yellow"},
	{"name": "ERROR", "color": "red"}
]

static var verbose: bool

static func log(data: Dictionary):
	if verbose == false and data.has("verbose"): return
	
	# Get log type
	var type: int = data.get("type", 0)
	var type_name = Console.log_types[type]['name']
	var type_color = Console.log_types[type]['color']
	var type_text: String = "[color=%s]%s[/color]" % [type_color, type_name]
	
	# Get log time
	var current_time: Dictionary = Time.get_time_dict_from_system()
	var formatted_time = "[color=#ebddcc]%02d:%02d:%02d[/color]" % [current_time['hour'], current_time['minute'], current_time['second']]
	
	# Get log message
	var message: String = data.get("message", "null")
	var formatted_log: String = "%s %s %s" % [type_text,formatted_time,message]
	print_rich(formatted_log)
	
	EventManager.console_logged.emit(formatted_log + "\n")
