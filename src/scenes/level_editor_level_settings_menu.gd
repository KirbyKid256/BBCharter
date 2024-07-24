extends Control
class_name LevelEditorSettings

@onready var level_name_field: LineEdit = $Settings/HBoxContainer/LevelNameField
@onready var character_name_field: LineEdit = $Settings/HBoxContainer2/CharacterNameField
@onready var character_color_field: LineEdit = $Settings/HBoxContainer2/CharacterColorField

@onready var song_offset_field: SpinBox = $Settings/HBoxContainer3/SongOffsetField

@onready var creator_field: LineEdit = $Settings/HBoxContainer4/CreatorField
@onready var song_title_field: LineEdit = $Settings/HBoxContainer5/SongTitleField
@onready var song_author_field: LineEdit = $Settings/HBoxContainer5/SongAuthorField
@onready var preview_timestamp_field: SpinBox = $Settings/HBoxContainer6/PreviewTimestampField
@onready var description_field: TextEdit = $Settings/HBoxContainer7/SongAuthorField

func _input(event):
	if MenuCache.menu_disabled(self): return
	if event.is_action("ui_cancel"): hide()

func _on_level_settings_button_up():
	var color = Config.meta.get('color', [0.5, 0.5, 0.5])
	color = Color(color[0], color[1], color[2])
	character_color_field.text = color.to_html(false)
	
	level_name_field.text = Config.meta.get('level_name', "My Level")
	character_name_field.text = Config.meta.get('character', "Character Name")
	song_offset_field.value = Config.settings.get('song_offset', 0.0)
	
	creator_field.text = Config.mod.get('creator', "Mod Creator Name")
	description_field.text = Config.mod.get('description', "This is my mod!")
	song_title_field.text = Config.mod.get('song_title', "My Song")
	song_author_field.text = Config.mod.get('song_author', "Song Author Name")
	preview_timestamp_field.value = Config.mod.get('preview_timestamp', 2.0)
	
	show()

func _on_save_button_up():
	Config.meta['level_name'] = level_name_field.text
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
	
	Editor.project_changed = true
	LevelEditor.controls_enabled = true
	hide()
