extends Control

func _ready():
	Global.save_indicator = $SaveIndicator
	Global.error_notification = $ErrorNotification
	Global.confirm_menu = $MenuOverlays/ConfirmMenu
	Global.file_dialog = $FileDialog
	Global.editor_menu = $MenuOverlays/LevelEditorMenu

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Global.editor_menu.toggle()
	
	if not Editor.controls_enabled: return
	
	if event.is_action_pressed("ui_editor_new"):
		Global.file_dialog.new_project()
	
	if event.is_action_pressed("ui_editor_open"):
		Global.file_dialog.open_project()
	
	if not Editor.project_loaded: return
	
	if event.is_action_pressed("ui_editor_save"):
		LevelEditor.save_level() 
		Global.save_indicator.show_saved_succes()
	
	if LevelEditor.selected_notes.size() > 0:
		if event.is_action_pressed("ui_editor_note_ghost"):
			var note = LevelEditor.selected_notes[0]
			note.run_action(note.GHOST)
		elif event.is_action_pressed("ui_editor_note_auto"):
			var note = LevelEditor.selected_notes[0]
			note.run_action(note.AUTO)
		elif event.is_action_pressed("ui_editor_note_voice"):
			var note = LevelEditor.selected_notes[0]
			note.run_action(note.VOICE)
		elif event.is_action_pressed("ui_editor_note_bomb"):
			var note = LevelEditor.selected_notes[0]
			note.run_action(note.BOMB)
	
	if event.is_action_pressed("editor_view_files"):
		OS.shell_open(Editor.project_path)

func _on_export_mod_button_up():
	var modpack_path = Editor.project_path.get_base_dir().get_base_dir()
	if FileAccess.file_exists(modpack_path.path_join("act.cfg")):
		await Editor.zip_directory(modpack_path, modpack_path + ".zip")
		OS.shell_open(modpack_path.get_base_dir())
		Global.editor_menu.toggle()
	else:
		if Editor.project_loaded:
			Global.error_notification.show_error("Level is not in an Act Folder")
		else:
			Global.error_notification.show_error("Level hasn't been opened")
