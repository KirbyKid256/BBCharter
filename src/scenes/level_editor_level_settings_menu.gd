extends Control
class_name LevelEditorSettings

enum {THUMB,SPLASH}

@onready var level_name_field: LineEdit = $Settings/HBoxContainer/LevelNameField
@onready var level_index_field: SpinBox = $Settings/HBoxContainer/LevelIndexField
@onready var character_name_field: LineEdit = $Settings/HBoxContainer2/CharacterNameField
@onready var character_color_field: LineEdit = $Settings/HBoxContainer2/CharacterColorField

@onready var song_offset_field: SpinBox = $Settings/HBoxContainer3/SongOffsetField

@onready var creator_field: LineEdit = $Settings/HBoxContainer4/CreatorField
@onready var song_title_field: LineEdit = $Settings/HBoxContainer5/SongTitleField
@onready var song_author_field: LineEdit = $Settings/HBoxContainer5/SongAuthorField
@onready var preview_timestamp_field: SpinBox = $Settings/HBoxContainer6/PreviewTimestampField
@onready var description_field: TextEdit = $Settings/HBoxContainer7/DescriptionField

@onready var thumb_select: Panel = $ThumbSelect
@onready var thumb_preview: TextureRect = $ThumbSelect/Preview
@onready var thumb_browse: Button = $ThumbSelect/Browse
@onready var splash_select: Panel = $SplashSelect
@onready var splash_preview: TextureRect = $SplashSelect/Preview
@onready var splash_browse: Button = $SplashSelect/Browse
@onready var file_dialog: FileDialog = $"../FileDialog"

var selected: int

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	
	thumb_browse.button_up.connect(func():
		selected = THUMB; file_dialog.popup())
	splash_browse.button_up.connect(func():
		selected = SPLASH; file_dialog.popup())

func _input(event):
	if not visible: return
	if event.is_action("ui_cancel"): hide()

func _on_editor_project_loaded():
	Assets.level_thumb = Files.load_image(Editor.project_path + "thumb.png")
	thumb_preview.texture = Assets.level_thumb
	Assets.level_splash = Files.load_image(Editor.project_path + "splash.png")
	splash_preview.texture = Assets.level_splash

func _on_level_settings_button_up():
	var color = Config.meta.get('color', [0.5, 0.5, 0.5])
	color = Color(color[0], color[1], color[2])
	character_color_field.add_theme_color_override("font_color", color)
	character_color_field.text = color.to_html(false)
	
	level_name_field.text = Config.meta.get('level_name', "My Level")
	level_index_field.value = Config.meta.get('level_index', 0)
	character_name_field.text = Config.meta.get('character', "Character Name")
	song_offset_field.value = Config.settings.get('song_offset', 0.0)
	
	creator_field.text = Config.mod.get('creator', "Mod Creator Name")
	description_field.text = Config.mod.get('description', "This is my mod!")
	song_title_field.text = Config.mod.get('song_title', "My Song")
	song_author_field.text = Config.mod.get('song_author', "Song Author Name")
	preview_timestamp_field.value = Config.mod.get('preview_timestamp', 2.0)
	
	show()

func _on_character_color_field_text_changed(new_text):
	var color = Color.from_string(character_color_field.text, Color.WHITE)
	character_color_field.add_theme_color_override("font_color", color)

func _on_thumb_select_mouse_entered():
	thumb_select.self_modulate = Color.WHITE

func _on_thumb_select_mouse_exited():
	thumb_select.self_modulate = Color8(255, 255, 255, 95)

func _on_splash_select_mouse_entered():
	splash_select.self_modulate = Color.WHITE

func _on_splash_select_mouse_exited():
	splash_select.self_modulate = Color8(255, 255, 255, 95)

func _on_file_dialog_file_selected(path):
	if not visible: return
	
	if selected == THUMB:
		var thumb: String = Editor.project_path + "thumb.png"
		DirAccess.copy_absolute(path, thumb)
		Assets.level_thumb = Files.load_image(thumb)
		thumb_preview.texture = Assets.level_thumb
	elif selected == SPLASH:
		var splash: String = Editor.project_path + "splash.png"
		DirAccess.copy_absolute(path, splash)
		Assets.level_splash = Files.load_image(splash)
		splash_preview.texture = Assets.level_splash

func _on_save_button_up():
	Config.meta['level_name'] = level_name_field.text
	Config.meta['level_index'] = int(level_index_field.value)
	Config.meta['character'] = character_name_field.text 
	Config.settings['song_offset'] = song_offset_field.value
	
	var color = Color.from_string(character_color_field.text, Color(0.5, 0.5, 0.5))
	Config.meta['color'] = [color.r, color.g, color.b]
	
	if not Config.mod.is_empty():
		Config.mod['creator'] = creator_field.text
		Config.mod['description'] = description_field.text
		Config.mod['song_title'] = song_title_field.text
		Config.mod['song_author'] = song_author_field.text
		Config.mod['preview_timestamp'] = preview_timestamp_field.value
	
	Editor.level_changed = true
	Editor.controls_enabled = true
	hide()
