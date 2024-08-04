class_name CutsceneEditor

static var data: Array = [{
	"lines": [],
	"characters": {},
	"global_tracks": []
}, {
	"lines": [],
	"characters": {},
	"global_tracks": []
}]

static func get_current_panel() -> Dictionary:
	if data[Cutscene.type].lines.is_empty(): return {}
	return data[Cutscene.type].lines[Cutscene.index]

static func save_scripts():
	Console.log({"message": "Saving Cutscenes", "verbose": true})
	
	var config: ConfigFile = ConfigFile.new()
	
	if Cutscene.exists(Cutscene.PRE):
		config.set_value('data', 'lines', data[0].lines)
		config.set_value('data', 'characters', data[0].characters)
		config.set_value('data', 'global_tracks', data[0].global_tracks)
		config.save(Cutscene.path(0) + "/script.cfg")
	
	if Cutscene.exists(Cutscene.POST):
		config.set_value('data', 'lines', data[1].lines)
		config.set_value('data', 'characters', data[1].characters)
		config.set_value('data', 'global_tracks', data[1].global_tracks)
		config.save(Cutscene.path(1) + "/script.cfg")

static func load_pre_script():
	Console.log({"message": "Loading Pre Cutscene", "verbose": true})
	
	var config: ConfigFile = ConfigFile.new()
	if config.load(Editor.project_path + "cutscene/pre/script.cfg") == OK:
		# Load data
		data[0].clear()
		data[0].lines = config.get_value('data', 'lines', [])
		data[0].characters = config.get_value('data', 'characters', {})
		data[0].global_tracks = config.get_value('data', 'global_tracks', [])
		
		# Validate Data
		if data[0].lines.size() < 1: Console.log({"message": "No Lines Found In Cutscene!", "type": 2})
	else:
		Console.log({"message": "Invalid cutscene config!", "type": 2})

static func load_post_script():
	Console.log({"message": "Loading Cutscenes", "verbose": true})
	
	var config: ConfigFile = ConfigFile.new()
	if config.load(Editor.project_path + "cutscene/post/script.cfg") == OK:
		# Load data
		data[1].clear()
		data[1].lines = config.get_value('data', 'lines', [])
		data[1].characters = config.get_value('data', 'characters', {})
		data[1].global_tracks = config.get_value('data', 'global_tracks', [])
		
		# Validate Data
		if data[1].lines.size() < 1: Console.log({"message": "No Lines Found In Cutscene!", "type": 2})
	else:
		Console.log({"message": "Invalid cutscene config!", "type": 2})
