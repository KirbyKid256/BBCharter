extends FileDialog

@onready var error_notification: ErrorNotification = $"../ErrorNotification"
@onready var timeline = $"../NoteTimeline/TimelineRoot"
@onready var music = $"../Music"

@onready var notes = $"../NoteTimeline/TimelineRoot/Notes"
@onready var indicators = $"../NoteTimeline/TimelineRoot/Indicators"
@onready var animations = $"../ScrollContainer/KeyframeAssetGrid/Animations/Track"
@onready var effects = $"../ScrollContainer/KeyframeAssetGrid/Effects/Track"
@onready var backgrounds = $"../ScrollContainer/KeyframeAssetGrid/Backgrounds/Track"
@onready var oneshots = $"../ScrollContainer/KeyframeAssetGrid/OneShotAudios/Track"
@onready var loopsounds = $"../ScrollContainer/KeyframeAssetGrid/SoundLoops/Track"
@onready var voices = $"../ScrollContainer/KeyframeAssetGrid/VoiceBanks/Track"
@onready var shutters = $"../ScrollContainer/KeyframeAssetGrid/Shutters/Track"
@onready var modifiers = $"../ScrollContainer/KeyframeAssetGrid/Modifiers/Track"

var create_level: bool
var asset_paths: Array

func _ready():
	current_dir = Global.get_executable_path()

func open_project():
	Console.log({'message': 'Opening New Project...'})
	title = "Select Project Directory"
	create_level = false
	popup()

func new_project():
	Console.log({'message': 'Creating New Project...'})
	title = "Create Project Directory"
	create_level = true
	popup()

func _on_dir_selected(new_path: String):
	var old_path = Editor.level_path
	Editor.level_path = new_path + "/"
	
	if create_level:
		LevelCreator.create_level_directories()
		LevelCreator.create_level_config()
	
	if Config.store_config_data():
		Editor.level_loaded = false
		Config.validate_ids()
		
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
		
		timeline.timeline_seek(0.0)
		
		# Asset Conversion Check
		ensure_climax_video()
		
		# Load Chart (besides notes)
		modifiers.load_keyframes()
		indicators.create_indicators()
		shutters.load_keyframes()
		
		# Load Assets
		load_game_assets()
		animations.load_keyframes()
		effects.load_keyframes()
		backgrounds.load_keyframes()
		oneshots.load_keyframes()
		loopsounds.load_keyframes()
		voices.load_keyframes()
		music.set_editor_music()
		
		await get_tree().process_frame
		EventManager.editor_level_loaded.emit()
		Editor.level_loaded = true
		
		Console.log({"message": "Finished Loading Level"})
	else:
		Console.log({"message": "Could Not Store Config Data!", "type": 2})
		Editor.level_path = old_path
		error_notification.show_error("Invalid Level Path")

## Ensures the climax video is in a format Godot can load, converting if needed
func ensure_climax_video():
	Console.log({"message": "Checking Climax Video..."})
	var climax_filename = Config.asset.get("final_video")
	if climax_filename == null: return
	if not FileAccess.file_exists(Editor.level_path + "video".path_join(climax_filename)): return

	match climax_filename.get_extension().to_lower():
		"webm","mp4","mov":
			Config.asset["final_video"] = FFmpeg.convert_file(
				Editor.level_path.path_join("video").path_join(climax_filename), # Input
				Editor.level_path.path_join("video/%s.ogv" % [climax_filename.get_basename()]),
				"ogg"
				)
		"ogv":
			Console.log({"message": "Final video already .ogv format"})
		_:
			Console.log({"message": "WARN Don't know how to handle climax format: %s" % climax_filename, "type": 1})

func load_game_assets():
	Console.log({"message": "Loading Game Assets..."})
	
	# Change Folder Paths if Legacy
	if Global.get_modtype() == Global.MODTYPE.LEGACY:
		asset_paths = ["anims","anims/fx","sfx","songs","textures","voice"]
	else:
		asset_paths = ["images","audio","video"]
	
	# Clear Old Assets
	Assets.lib.clear()
	
	# Get New Assets
	for asset_path in asset_paths:
		if asset_path == "voice" and DirAccess.dir_exists_absolute(Editor.level_path + "voice") and DirAccess.get_directories_at(Editor.level_path + "voice").size() > 0:
			for bank in DirAccess.get_directories_at(Editor.level_path + "voice"): if DirAccess.get_files_at(Editor.level_path + "voice/%s" % bank).size() > 0:
				for file in DirAccess.get_files_at(Editor.level_path + "voice/%s" % bank):
					Assets.load_asset(Editor.level_path + "voice/%s/%s" % [bank, file])
		else:
			for file in DirAccess.get_files_at(Editor.level_path + asset_path):
				Assets.load_asset(Editor.level_path + asset_path + "/" + file)
