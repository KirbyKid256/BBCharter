class_name LevelCreator

static var act_template = { # act.cfg
	"act_index": 0,
	"act_name": "My Act",
	"act_description": "My Description"
}

static var config_templates = [
	{ # asset.cfg
		"song_path":"template_song.ogg",
		"horny_mode_sound":"",
		"final_video": "",
		"final_audio": ""
	},
	{ # keyframes.cfg
		"loops": [],
		"effects": [],
		"background": [],
		"modifiers": [{"bpm": 120.0,"timestamp": 0.0}],
		"shutter": [],
		"sound_loop": [],
		"sound_oneshot": [],
		"voice_bank": [],
	},
	{ # meta.cfg
		"level_index":0,
		"character": "My Character",
		"color": [0.5, 0.5, 0.5],
		"level_name":"My Level",
	},
	{ # mod.cfg
		"description": "This is my mod!",
		"song_title": "My Song",
		"song_author": "Song Author Name",
		"creator": "Mod Creator Name",
		"preview_timestamp": 2.0
	},
	{ # notes.cfg
		"charts": [{
			"name": "Normal",
			"rating": 0,
			"notes": [
				{"input_type": 0, "note_modifier": 0, "timestamp": 0.0}, 
				{"input_type": 0, "note_modifier": 0, "timestamp": 0.5}, 
				{"input_type": 0, "note_modifier": 0, "timestamp": 1.0}, 
				{"input_type": 0, "note_modifier": 0, "timestamp": 1.5}, 
				{"input_type": 0, "note_modifier": 0, "timestamp": 2.0}, 
				{"input_type": 0, "note_modifier": 0, "timestamp": 2.5}, 
				{"input_type": 0, "note_modifier": 0, "timestamp": 3.0}, 
				{"input_type": 0, "note_modifier": 0, "timestamp": 3.5}, 
				{"input_type": 1, "note_modifier": 0, "timestamp": 4.0}, 
				{"input_type": 1, "note_modifier": 0, "timestamp": 4.5}, 
				{"input_type": 1, "note_modifier": 0, "timestamp": 5.0}, 
				{"input_type": 1, "note_modifier": 0, "timestamp": 5.5}, 
				{"input_type": 1, "note_modifier": 0, "timestamp": 6.0}, 
				{"input_type": 1, "note_modifier": 0, "timestamp": 6.5}, 
				{"input_type": 1, "note_modifier": 0, "timestamp": 7.0}, 
				{"input_type": 1, "note_modifier": 0, "timestamp": 7.5}
			]
		}]
	},
	{ # settings.cfg
		"song_offset": 2.0,
		"post_song_delay":5.0,
		"note_offset":0.0,
	}
]

static var cutscene_script_template = [{
	"character": "Sample Character",
	"dialogue": "Sample Dialogue"
}]

static func create_act_config():
	Console.log({"message": "Creating Modpack Config"})
	Config.act = act_template.duplicate()
	
	var act_config = ConfigFile.new()
	act_config.set_value("main", "data", act_template)
	act_config.save(Editor.project_path.get_base_dir().get_base_dir().path_join("act.cfg"))

static func create_act_placeholders():
	Console.log({"message": "Creating Modpack Placeholders"})
	var thumb: Image = preload("res://assets/images/placeholder_album_cover.png").get_image()
	thumb.save_png(Editor.project_path.get_base_dir().get_base_dir().path_join("thumb.png"))

static func create_level_directories():
	for folder_name in ["audio","config","images","video"]:
		Console.log({"message": "Creating %s Folder" % folder_name})
		if not DirAccess.make_dir_absolute(Editor.project_path.path_join(folder_name)) == OK: continue

static func create_level_config():
	var template_names = ["asset.cfg","keyframes.cfg","meta.cfg","mod.cfg","notes.cfg","settings.cfg"]
	for i in template_names.size():
		var template_name = template_names[i]
		var config_template = config_templates[i]
		var new_config = ConfigFile.new() 
		
		new_config.set_value("main", "data", config_template)
		new_config.save(Editor.project_path.path_join("config").path_join(template_name))

static func create_level_placeholders():
	Console.log({"message": "Creating Level Placeholders"})
	
	var thumb: Image = preload("res://assets/images/placeholder_level_icon.png").get_image()
	thumb.save_png(Editor.project_path + "thumb.png")
	
	var splash: Image = preload("res://assets/images/placeholder_splash.png").get_image()
	splash.save_png(Editor.project_path + "splash.png")
	
	var song: String = Global.get_executable_path().path_join("data/_template/template_song.ogg")
	if FileAccess.file_exists(song): DirAccess.copy_absolute(song, Editor.project_path + "audio/template_song.ogg")

static func create_cutscene():
	var type: String
	match Cutscene.type:
		Cutscene.PRE: type = "pre"
		Cutscene.POST: type = "post"
	
	var dir = DirAccess.open(Editor.project_path)
	dir.make_dir_recursive("cutscene/%s/shots" % type)
	dir.make_dir_recursive("cutscene/%s/audio" % type)
	
	if not FileAccess.file_exists(Editor.project_path + "cutscene/%s/script.cfg" % type):
		var config = ConfigFile.new()
		config.set_value("data", "lines", cutscene_script_template)
		config.save(Editor.project_path + "cutscene/%s/script.cfg" % type)
		CutsceneEditor.load_pre_script() if type == "pre" else CutsceneEditor.load_post_script()
