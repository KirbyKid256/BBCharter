extends Control

@export var voice_asset: PackedScene

@onready var file_selection: ScrollContainer = $'../MenuOverlays/CreateAudioMenu/FileSelection'

@onready var create_audio_menu: Control = $'../MenuOverlays/CreateAudioMenu'
@onready var create_audio_header: Label = $'../MenuOverlays/CreateAudioMenu/Header'
@onready var create_audio_voice_paths: VBoxContainer = $'../MenuOverlays/CreateAudioMenu/Paths/AssetGrid'

@onready var create_image_menu: Control = $'../MenuOverlays/CreateImageMenu'
@onready var create_image_header: Label = $'../MenuOverlays/CreateImageMenu/Header'
@onready var create_image_label: Label = $'../MenuOverlays/CreateImageMenu/FileName'
@onready var create_image_button: Button = $'../MenuOverlays/CreateImageMenu/Buttons/Create'
@onready var sheet_preview: TextureRect = $'../MenuOverlays/CreateImageMenu/SheetPreview'

@onready var sheet_data: HBoxContainer = $'../MenuOverlays/CreateImageMenu/Settings/SheetData'
@onready var h_frames: SpinBox = $'../MenuOverlays/CreateImageMenu/Settings/SheetData/HFrames'
@onready var v_frames: SpinBox = $'../MenuOverlays/CreateImageMenu/Settings/SheetData/VFrames'
@onready var total_frames: SpinBox = $'../MenuOverlays/CreateImageMenu/Settings/SheetData/TotalFrames'
@onready var scale_multiplier: SpinBox = $'../MenuOverlays/CreateImageMenu/Settings/Scale'
@onready var duration: SpinBox = $'../MenuOverlays/CreateImageMenu/Settings/Duration'
@onready var expand_mode: OptionButton = $'../MenuOverlays/CreateImageMenu/Settings/Expand'
@onready var stretch_mode: OptionButton = $'../MenuOverlays/CreateImageMenu/Settings/Stretch'

@onready var sheet_data_label: Label = $'../MenuOverlays/CreateImageMenu/Settings/Label'
@onready var scale_label: Label = $'../MenuOverlays/CreateImageMenu/Settings/Label2'
@onready var duration_label: Label = $'../MenuOverlays/CreateImageMenu/Settings/Label3'
@onready var expand_label: Label = $'../MenuOverlays/CreateImageMenu/Settings/Label4'
@onready var stretch_label: Label = $'../MenuOverlays/CreateImageMenu/Settings/Label5'

@onready var cache_assets: Control = $'../Assets/Cache'
@onready var file_assets: Control = $'../Assets/Files'
@onready var music: AudioStreamPlayer = $'../Music'

var replacement_data: Dictionary

var pending_image_file: String
var pending_image_type: int = -1

var pending_audio_data: Dictionary

func _ready():
	EventManager.editor_create_image_keyframe.connect(create_image_keyframe)
	EventManager.editor_create_audio_keyframe.connect(create_audio_keyframe)
	
	get_viewport().files_dropped.connect(_on_files_dropped)
	file_selection.button_up.connect(_on_file_button_up)

func _on_files_dropped(files: PackedStringArray):
	for file in files:
		if ['gif','mp4','webm'].has(file.get_extension()): make_spritesheet(file); continue
		if ['png','jpg','jpeg','webp'].has(file.get_extension()): import_image(file); continue
		if ['ogg','mp3'].has(file.get_extension()): import_audio(file); continue
	
	file_selection.reload_list()

func make_spritesheet(file):
	var data = FFmpeg.create_sprite_sheet_from_gif(file)
	add_new_animation_asset(data)
	Assets.load_asset(data['output'])
	file_assets.get_files()

#region Image File Drop
# TODO: Fix this from running too many times
func import_image(file: String):
	# TODO: Ask for confirmation to overwrite existing file
	var new_file = Editor.project_path + "images/" + file.get_file()
	DirAccess.copy_absolute(file, new_file)
	Assets.load_asset(new_file)
	file_assets.get_files()

func create_image_keyframe(data: Dictionary, type: int, replace: bool = false):
	if create_audio_menu.visible: return # Dont show if importing audio
	if replace: replacement_data = data.duplicate(true)
	
	if data.has("sheet_data"):
		h_frames.value = data.sheet_data.h
		v_frames.value = data.sheet_data.v
		total_frames.value = data.sheet_data.total
	if data.has("scale_multiplier"):
		scale_multiplier.value = data.scale_multiplier
	if data.has("duration"):
		scale_multiplier.value = data.scale_multiplier
	if data.has("expand_mode"):
		expand_mode.selected = data.expand_mode
	if data.has("stretch_mode"):
		stretch_mode.selected = data.stretch_mode
	
	create_image_header.text = "Enter %s Information" % LevelEditor.IMAGE.keys()[type].capitalize()
	create_image_button.text = "Create %s" % LevelEditor.IMAGE.keys()[type].capitalize()
	
	match type:
		LevelEditor.IMAGE.ANIMATION:
			sheet_data.show()
			sheet_data_label.show()
			scale_multiplier.show()
			scale_label.show()
			
			duration.hide()
			duration_label.hide()
			expand_mode.hide()
			expand_label.hide()
			stretch_mode.hide()
			stretch_label.hide()
		LevelEditor.IMAGE.EFFECT:
			sheet_data.show()
			sheet_data_label.show()
			duration.show()
			duration_label.show()
			
			scale_multiplier.hide()
			scale_label.hide()
			expand_mode.hide()
			expand_label.hide()
			stretch_mode.hide()
			stretch_label.hide()
		LevelEditor.IMAGE.BACKGROUND:
			sheet_data.hide()
			sheet_data_label.hide()
			scale_multiplier.hide()
			scale_label.hide()
			duration.hide()
			duration_label.hide()
			
			expand_mode.show()
			expand_label.show()
			stretch_mode.show()
			stretch_label.show()
	
	pending_image_file = data["sprite_sheet"]
	pending_image_type = type
	create_image_menu.show()
	create_image_label.text = pending_image_file
	sheet_preview.texture = Assets.get_asset(pending_image_file)
	Editor.controls_enabled = false

func _on_image_import_button_up():
	if pending_image_file.is_empty(): return
	if not FileAccess.file_exists(Editor.project_path + "images/" + pending_image_file.get_file()):
		DirAccess.copy_absolute(pending_image_file, Editor.project_path + "images/" + pending_image_file.get_file())
	
	var data: Dictionary = {"sprite_sheet": pending_image_file.get_file()}
	if sheet_data.visible:
		data.merge({"sheet_data": {
			"h": int(h_frames.value),
			"v": int(v_frames.value),
			"total": int(total_frames.value),
			}
		})
	if scale_multiplier.visible and scale_multiplier.value != 1:
		data.merge({"scale_multiplier": scale_multiplier.value})
	if duration.visible:
		data.merge({"duration": duration.value})
	if expand_mode.visible and expand_mode.selected != TextureRect.EXPAND_IGNORE_SIZE:
		data.merge({"expand_mode": expand_mode.selected})
	if stretch_mode.visible and stretch_mode.selected != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		data.merge({"stretch_mode": stretch_mode.selected})
	
	add_new_animation_asset(data, pending_image_type)
	Editor.controls_enabled = true

func _on_image_cancel_button_up():
	pending_image_file = ""
	create_image_menu.hide()
	Editor.controls_enabled = true
#endregion

#region Audio File Drop
# Pend audio file and open audio type menu
func import_audio(file: String):
	# TODO: Ask for confirmation to overwrite existing file
	if file.get_extension() != "ogg" and file.get_extension() != "mp3":
		var converted_audio = FFmpeg.convert_file(file, Editor.project_path + "audio/" + file.get_file().get_basename() + ".ogg", "ogg")
		Assets.load_asset(converted_audio)
	else:
		var new_file = Editor.project_path + "audio/" + file.get_file()
		DirAccess.copy_absolute(file, new_file)
		Assets.load_asset(new_file)
	file_assets.get_files()

func create_audio_keyframe(data: Dictionary, replace: bool = false):
	if create_image_menu.visible: return # Dont show if importing image
	if replace: replacement_data = data.duplicate(true)
	
	pending_audio_data = data
	
	reload_path_list_audio()
	file_selection.reload_list()
	
	create_audio_menu.show()
	Editor.controls_enabled = false

func reload_path_list_audio():
	Util.clear_children(create_audio_voice_paths)
	
	for path in pending_audio_data['audio_path']:
		var asset = voice_asset.instantiate() as Control
		create_audio_voice_paths.add_child(asset)
		asset.setup(path)

func _on_file_button_up(text):
	pending_audio_data['audio_path'].append(text)
	
	var asset = voice_asset.instantiate() as Control
	create_audio_voice_paths.add_child(asset)
	asset.setup(text)

func _on_audio_create_button_up():
	if pending_audio_data.is_empty(): return
	
	add_new_audio_asset(pending_audio_data)
	Editor.controls_enabled = true

func _on_audio_cancel_button_up():
	create_audio_menu.hide()
	Editor.controls_enabled = true
#endregion

# Add new image asset to editor cache and load it from the Asset Autoload
func add_new_animation_asset(data: Dictionary, type: int = -1):
	if replacement_data: LevelEditor.replace_asset_cache(replacement_data, data)
	else: LevelEditor.append_asset_cache(data)
	create_image_menu.hide()
	
	replacement_data = {}
	pending_image_file = ""
	pending_image_type = -1
	
	await get_tree().process_frame
	cache_assets.get_image_assets(type)

# Add new image asset to editor cache and load it from the Asset Autoload
func add_new_audio_asset(data: Dictionary):
	if replacement_data: LevelEditor.replace_asset_cache(replacement_data, data)
	else: LevelEditor.append_asset_cache(data)
	create_audio_menu.hide()
	
	replacement_data = {}
	pending_audio_data = {}
	
	await get_tree().process_frame
	cache_assets.get_audio_assets()
