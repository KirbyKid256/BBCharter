extends Control
class_name LevelEditorSettings

# Fields
@onready var level_name_field: LineEdit = $Settings/HBoxContainer/LevelNameField
@onready var character_name_field: LineEdit = $Settings/HBoxContainer2/CharacterNameField
@onready var character_color_field: LineEdit = $Settings/HBoxContainer3/CharacterColorField
@onready var song_offset_field: SpinBox = $Settings/HBoxContainer4/SongOffsetField

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)

func _input(event):
	if MenuCache.menu_disabled(self): return
	if event.is_action("ui_cancel"): hide()

func _on_editor_level_loaded():
	var color = Config.meta.get('color', [0.5, 0.5, 0.5])
	color = Color(color[0], color[1], color[2])
	character_color_field.text = color.to_html(false)
	
	level_name_field.text = Config.meta.get('level_name', "My Level")
	character_name_field.text = Config.meta.get('character', "Character Name")
	song_offset_field.value = Config.settings.get('song_offset', 0.0)

func _on_save_button_up():
	Config.meta['level_name'] = level_name_field.text
	Config.meta['character'] = character_name_field.text 
	Config.settings['song_offset'] = song_offset_field.value
	
	var color = Color.from_string(character_color_field.text, Color(0.5, 0.5, 0.5))
	Config.meta['color'] = [color.r, color.g, color.b]
	
	hide()
	Config.save_config_data("settings.cfg", Config.settings)
	LevelEditor.controls_enabled = true
