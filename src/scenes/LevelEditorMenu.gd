extends Control
class_name LevelEditorMenu

@onready var music: LevelEditorMusic = $'../../Music'
@onready var subheader: Label = $Subheader
@onready var save_indicator: SaveIndicator = $'../../SaveIndicator'

func toggle():
	visible = !visible
	if visible: music.pause()
	
	subheader.text = "%s - %s" % [
		Config.meta.get("level_name", "No Name"),
		Config.notes['charts'][MenuCache.level_difficulty_index]['name']
	]

func _on_close_menu_button_up():
	hide()

func _on_level_settings_button_up():
	hide()

func _on_save_level_button_up():
	LevelEditor.save_project() 
	save_indicator.show_saved_succes()
	hide()

func _exit_tree():
	LevelEditor.controls_enabled = true
