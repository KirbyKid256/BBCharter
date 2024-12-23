extends FileDialog

@onready var confirm_menu = $"../MenuOverlays/ConfirmMenu"
@onready var timeline = $"../NoteTimeline/TimelineRoot"
@onready var music = $"../Music"

@onready var notes = $"../NoteTimeline/TimelineRoot/Notes"
@onready var indicators = $"../NoteTimeline/TimelineRoot/Indicators"
@onready var animations = $"../ScrollContainer/Keyframes/Animations/Track"
@onready var effects = $"../ScrollContainer/Keyframes/Effects/Track"
@onready var backgrounds = $"../ScrollContainer/Keyframes/Backgrounds/Track"
@onready var oneshots = $"../ScrollContainer/Keyframes/OneShotAudios/Track"
@onready var loopsounds = $"../ScrollContainer/Keyframes/LoopSounds/Track"
@onready var voices = $"../ScrollContainer/Keyframes/VoiceBanks/Track"
@onready var shutters = $"../ScrollContainer/Keyframes/Shutters/Track"
@onready var modifiers = $"../ScrollContainer/Keyframes/Modifiers/Track"

var create_level: bool

func _ready():
	current_dir = Editor.project_path if Editor.project_loaded else Global.get_executable_path()

func open_project():
	Console.log({'message': 'Opening New Project...'})
	title = "Select Project Directory"
	popup()

func new_project():
	Console.log({'message': 'Creating New Project...'})
	title = "Create Project Directory"
	create_level = true
	popup()

func _on_dir_selected(new_path: String):
	if Editor.project_changed():
		confirm_menu.open()
		confirm_menu.close_signal = func():
			Editor.level_changed = false
			Global.undo_redo.clear_history(Global.undo_redo.get_version() != Editor.saved_version)
			Editor.saved_version = Global.undo_redo.get_version()
			_on_dir_selected(new_path)
		return
	
	var old_path = Editor.project_path
	Editor.project_path = new_path + "/"
	
	if create_level:
		Config.act.clear()
		LevelCreator.create_level_directories()
		LevelCreator.create_level_placeholders()
		LevelCreator.create_level_config()
		create_level = false
	
	if Config.store_config_data():
		Editor.project_loaded = false
		Config.validate_ids()
		
		# Don't need to do this twice
		if not confirm_menu.visible:
			Global.undo_redo.clear_history(Global.undo_redo.get_version() != Editor.saved_version)
			Editor.saved_version = Global.undo_redo.get_version()
		
		# Auto-Generate Asset Cache if possible
		if LevelEditor.get_asset_cache().is_empty():
			for key in ["loops", "effects", "background", "sound_loop", "voice_bank"]: for data in Config.keyframes[key]:
				if data.is_empty(): continue
				
				data = data.duplicate(true)
				data.erase("timestamp")
				
				match key:
					"loops":
						if data.animations.normal.is_empty(): continue
						data["sprite_sheet"] = data.animations.normal
						data.erase("animations")
					"sound_loop":
						if typeof(data.path) != TYPE_ARRAY: continue
						data.audio_path = data.path
						data.erase("path")
					"voice_bank":
						if data.voice_paths.is_empty(): continue
						data.audio_path = data.voice_paths
						data.erase("voice_paths")
					_:
						if data.path.is_empty(): continue
						data.sprite_sheet = data.path
						data.erase("path")
				
				LevelEditor.append_asset_cache(data)
		
		# Clear everything and start fresh
		Util.clear_children(notes)
		Util.clear_children(animations)
		Util.clear_children(effects)
		Util.clear_children(backgrounds)
		Util.clear_children(shutters)
		Util.clear_children(oneshots)
		Util.clear_children(loopsounds)
		Util.clear_children(voices)
		Util.clear_children(modifiers)
		
		Util.clear_children(indicators.beats)
		Util.clear_children(indicators.half_beats)
		Util.clear_children(indicators.third_beats)
		Util.clear_children(indicators.quarter_beats)
		Util.clear_children(indicators.sixth_beats)
		Util.clear_children(indicators.eighth_beats)
		
		# Asset Conversion Check
		ensure_climax_video()
		
		# Load Chart (besides notes)
		modifiers.load_keyframes()
		indicators.create_indicators()
		shutters.load_keyframes()
		
		# Load Assets
		load_game_assets()
		music.set_editor_music()
		timeline.timeline_seek(0)
		
		animations.load_keyframes()
		effects.load_keyframes()
		backgrounds.load_keyframes()
		oneshots.load_keyframes()
		loopsounds.load_keyframes()
		voices.load_keyframes()
		
		await get_tree().process_frame
		Cutscene.type = Cutscene.PRE
		EventManager.editor_project_loaded.emit()
		Editor.project_loaded = true
		
		Console.log({"message": "Finished Loading Level"})
	else:
		Console.log({"message": "Could Not Store Config Data!", "type": 2})
		Editor.project_path = old_path
		Global.error_notification.show_error("Invalid Level Path")

## Ensures the climax video is in a format Godot can load, converting if needed
func ensure_climax_video():
	Console.log({"message": "Checking Climax Video..."})
	var climax_filename = Config.asset.get("final_video")
	if climax_filename == null: return
	if not FileAccess.file_exists(Editor.project_path + "video".path_join(climax_filename)): return

	match climax_filename.get_extension().to_lower():
		"webm","mp4","mov":
			Config.asset["final_video"] = FFmpeg.convert_file(
				Editor.project_path.path_join("video").path_join(climax_filename), # Input
				Editor.project_path.path_join("video/%s.ogv" % [climax_filename.get_basename()]),
				"ogg"
				)
		"ogv":
			Console.log({"message": "Final video already .ogv format"})
		_:
			Console.log({"message": "WARN Don't know how to handle climax format: %s" % climax_filename, "type": 1})

func load_game_assets():
	Console.log({"message": "Loading Game Assets..."})
	
	# Change Folder Paths if Legacy
	var asset_paths: Array = ["images","audio","video"]
	if Editor.get_modtype() == Editor.MODTYPE.LEGACY:
		asset_paths = ["anims","anims/fx","sfx","songs","textures","voice"]
	
	# Clear Old Assets
	Assets.lib.clear()
	
	# Get New Assets
	for asset_path in asset_paths:
		if asset_path == "voice" and DirAccess.dir_exists_absolute(Editor.project_path + "voice") and DirAccess.get_directories_at(Editor.project_path + "voice").size() > 0:
			for bank in DirAccess.get_directories_at(Editor.project_path + "voice"): if DirAccess.get_files_at(Editor.project_path + "voice/%s" % bank).size() > 0:
				for file in DirAccess.get_files_at(Editor.project_path + "voice/%s" % bank):
					Assets.load_asset(Editor.project_path + "voice/%s/%s" % [bank, file])
		else:
			for file in DirAccess.get_files_at(Editor.project_path + asset_path):
				Assets.load_asset(Editor.project_path + asset_path + "/" + file)
