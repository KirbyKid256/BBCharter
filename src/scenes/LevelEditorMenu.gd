extends Control
class_name LevelEditorMenu

@onready var music: LevelEditorMusic = $'../../Music'
@onready var subheader: Label = $Subheader
@onready var save_indicator: SaveIndicator = $'../../SaveIndicator'

@onready var act_settings: Button = $Groups/VBoxContainer/ActSettingsButton

var in_submenu: bool = false

func _input(event):
	await get_tree().process_frame
	if event.is_action("ui_cancel") and in_submenu:
		close_submenu()

func toggle():
	if not Editor.level_loaded: return
	if in_submenu: return
	
	LevelEditor.controls_enabled = visible
	
	subheader.text = "%s - %s" % [
		Config.meta.get("level_name", "No Name"),
		Config.notes['charts'][MenuCache.level_difficulty_index]['name']
	]
	
	if Config.act.is_empty():
		act_settings.text = "Create Act"
	else:
		act_settings.text = "Act Settings"
	
	visible = !visible
	if visible: music.pause()

func open_submenu():
	in_submenu = true
	hide()

func close_submenu():
	in_submenu = false
	toggle()

func _on_save_level_button_up():
	LevelEditor.save_project() 
	save_indicator.show_saved_succes()
	hide()
