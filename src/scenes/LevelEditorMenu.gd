extends Control

@onready var music: LevelEditorMusic = $'../../Music'
@onready var subheader: Label = $Subheader

@onready var act_settings: Button = $Groups/VBoxContainer/ActSettingsButton

var in_submenu: bool

func _input(event):
	await get_tree().process_frame
	if event.is_action("ui_cancel") and in_submenu:
		close_submenu()

func toggle():
	if not Editor.project_loaded: return
	if in_submenu: return
	
	Editor.controls_enabled = visible
	
	subheader.text = "%s - %s" % [
		Config.meta.get("level_name", "No Name"),
		Config.notes['charts'][LevelEditor.difficulty_index]['name']
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
	LevelEditor.save_level() 
	Global.save_indicator.show_saved_succes()
	toggle()

func _on_save_project_button_up():
	Editor.save_project() 
	Global.save_indicator.show_saved_succes()
	toggle()
