extends Control

@onready var level_editor_menu: LevelEditorMenu = $MenuOverlays/LevelEditorMenu

@onready var save_indicator: SaveIndicator = $SaveIndicator
@onready var error_notification: ErrorNotification = $ErrorNotification

@onready var file_dialog: FileDialog = $FileDialog

func _input(event):
	if MenuCache.menu_disabled(self): return
	
	if event.is_action_pressed("ui_cancel"):
		level_editor_menu.toggle()
	
	if level_editor_menu.visible: return
	if not LevelEditor.controls_enabled: return
	
	if event.is_action_pressed("ui_editor_new"):
		file_dialog.new_project()
	
	if event.is_action_pressed("ui_editor_open"):
		file_dialog.open_project()
	
	if event.is_action_pressed("ui_editor_save"):
		LevelEditor.save_project() 
		save_indicator.show_saved_succes()
	
	if LevelEditor.selected_notes.size() >= 1:
		if event.is_action_pressed("ui_editor_note_ghost"):
			for note: EditorNote in LevelEditor.selected_notes: note.run_action(note.GHOST)
		elif event.is_action_pressed("ui_editor_note_auto"):
			for note: EditorNote in LevelEditor.selected_notes: note.run_action(note.AUTO)
		elif event.is_action_pressed("ui_editor_note_voice"):
			for note: EditorNote in LevelEditor.selected_notes: note.run_action(note.VOICE)
		elif event.is_action_pressed("ui_editor_note_hold"):
			for note: EditorNote in LevelEditor.selected_notes: note.run_action(note.HOLD)
		elif event.is_action_pressed("ui_editor_note_bomb"):
			for note: EditorNote in LevelEditor.selected_notes: note.run_action(note.BOMB)
	
	if event.is_action_pressed("editor_view_files"):
		OS.shell_open(Editor.level_path)

func _on_export_mod_button_up():
	var modpack_path = Editor.level_path.get_base_dir().get_base_dir()
	if FileAccess.file_exists(modpack_path.path_join("act.cfg")):
		await zip_directory(modpack_path, modpack_path + ".zip")
		OS.shell_open(modpack_path)
		level_editor_menu.hide()
	else:
		if Editor.level_loaded:
			error_notification.show_error("Level is not in an Act Folder")
		else:
			error_notification.show_error("Level hasn't been opened")

func zip_directory(folder_path: String, dest_path: String):
	var packer = ZIPPacker.new()
	packer.open(dest_path)
	await dir_contents(packer, folder_path)
	packer.close()

func dir_contents(packer: ZIPPacker, path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				dir_contents(packer, path + "/" + file_name)
			else:
				var write_path = path + "/" + file_name
				var relative_path = write_path.trim_prefix(path.get_base_dir().get_base_dir() + "/")
				packer.start_file(relative_path)
				packer.write_file(FileAccess.get_file_as_bytes(write_path))
				packer.close_file()
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
