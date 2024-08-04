extends Control

@onready var subheader: Label = $Subheader
@onready var pre_post_button: Button = $Groups/VBoxContainer/PrePostButton

@onready var save_indicator: SaveIndicator = $'../../SaveIndicator'
@onready var error_notification: ErrorNotification = $'../../ErrorNotification'

func toggle():
	if not Editor.project_loaded: return
	
	subheader.text = "Pre-Cutscene" if Cutscene.type == 0 else "Post-Cutscene"
	
	var dir = DirAccess.open(Editor.project_path)
	pre_post_button.text = ("Edit" if dir.dir_exists("cutscene/%s" % ["post","pre"][Cutscene.type]) else "Create")\
	+ (" Pre-Cutscene" if Cutscene.type != 0 else " Post-Cutscene")
	
	Editor.controls_enabled = visible
	visible = !visible

func _on_save_cutscene_button_up():
	CutsceneEditor.save_scripts() 
	Global.save_indicator.show_saved_succes()
	hide()

func _on_save_project_button_up():
	Editor.save_project() 
	Global.save_indicator.show_saved_succes()
	hide()

func _on_export_mod_button_up():
	var modpack_path = Editor.project_path.get_base_dir().get_base_dir()
	if FileAccess.file_exists(modpack_path.path_join("act.cfg")):
		await Editor.zip_directory(modpack_path, modpack_path + ".zip")
		OS.shell_open(modpack_path.get_base_dir())
		hide()
	else:
		if Editor.project_loaded:
			Global.error_notification.show_error("Level is not in an Act Folder")
		else:
			Global.error_notification.show_error("Level hasn't been opened")

func _on_level_editor_button_up():
	Editor.controls_enabled = true
	get_tree().change_scene_to_file("res://src/scenes/level_editor.tscn")
