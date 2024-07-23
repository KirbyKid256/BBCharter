extends Button

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)

func _on_editor_level_loaded():
	var dir = DirAccess.open(Editor.level_path)
	if dir.dir_exists("cutscene"): text = "Edit Cutscene"
	else: text = "Create Cutscene"
	#disabled = false

func _on_button_up():
	var dir = DirAccess.open(Editor.level_path)
	if not dir.dir_exists("cutscene/pre"):
		make_cutscene("pre")
	
	#Cutscene.change_path(Cutscene.PRE)
	if load_script():
		LevelEditor.controls_enabled = false

func make_cutscene(type: String):
	var dir = DirAccess.open(Editor.level_path)
	dir.make_dir_recursive("cutscene/%s/shots" % type)
	dir.make_dir_recursive("cutscene/%s/audio" % type)
	
	if not FileAccess.file_exists(Editor.level_path + "cutscene/%s/script.cfg" % type):
		var config = ConfigFile.new()
		config.set_value("data", "lines", LevelCreator.cutscene_script_template)
		config.save(Editor.level_path + "cutscene/%s/script.cfg" % type)
		await get_tree().process_frame

func load_script() -> bool:
	return false
	#Console.log({"message": "Loading Cutscene At Path: %s" % Cutscene.path, "verbose": true})
	#var config: ConfigFile = ConfigFile.new()
	
	#if config.load(Cutscene.path.path_join("script.cfg")) == OK:
		#Cutscene.lines = config.get_value('data', 'lines', [])
		#Cutscene.characters = config.get_value('data', 'characters', {})
		#Cutscene.global_tracks = config.get_value('data', 'global_tracks', [])
		
		#if Cutscene.lines.size() < 1: Console.log({"message": "No Lines Found In Cutscene!", "type": 2}); return false
		#EventManager.emit_signal("cutscene_loaded")
		
		#Cutscene.current_panel = Cutscene.lines[Cutscene.cutscene_index]
		#EventManager.emit_signal("cutscene_panel_changed")
		#return true
	#else:
		#Console.log({"message": "Invalid cutscene config!", "type": 2})
		#return false
