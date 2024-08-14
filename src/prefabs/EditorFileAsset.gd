extends Control

@onready var music: LevelEditorMusic = $"../../../../../Music"
@onready var file_drop: Control = $"../../../../../FileDrop"

@onready var filename: Label = $Filename
@onready var level_editor_icon: Sprite2D = $LevelEditorIcon

@onready var context_menu_image: PopupMenu = $ContextMenuImage
@onready var context_menu_audio: PopupMenu = $ContextMenuAudio

var data: Dictionary

func setup(file_data):
	data = file_data
	if data.get("sprite_sheet"):
		filename.text = data["sprite_sheet"]
		level_editor_icon.texture = preload("res://assets/ui/level_editor_icon_image.png")
	elif data.get("audio_path"):
		filename.text = data["audio_path"]
		level_editor_icon.texture = preload("res://assets/ui/level_editor_icon_audio.png")
	tooltip_text = filename.text

func _on_mouse_entered():
	level_editor_icon.modulate.a = 1.0

func _on_mouse_exited():
	level_editor_icon.modulate.a = 0.3

func _on_gui_input(event: InputEvent):
	if data.get("sprite_sheet"):
		if EventManager.left_mouse_clicked(event):
			EventManager.editor_create_image_keyframe.emit(data, LevelEditor.IMAGE.ANIMATION)
		elif EventManager.right_mouse_clicked(event):
			context_menu_image.set_position(global_position + event.position)
			context_menu_image.popup()
	elif data.get("audio_path"):
		if EventManager.left_mouse_clicked(event):
			EventManager.editor_try_add_oneshot.emit(data)
		elif EventManager.right_mouse_clicked(event):
			context_menu_audio.set_position(global_position + event.position)
			context_menu_audio.popup()

func _on_context_menu_image_id_pressed(id):
	if id < LevelEditor.IMAGE.size(): EventManager.editor_create_image_keyframe.emit(data, id)
	else:
		DirAccess.remove_absolute(Editor.project_path + "images/" + filename.text)
		Util.free_node(self)

func _on_context_menu_audio_id_pressed(id):
	match id:
		LevelEditor.AUDIO.ONESHOT: EventManager.editor_try_add_oneshot.emit(data)
		LevelEditor.AUDIO.LOOP: EventManager.editor_try_add_loopsound.emit(data)
		LevelEditor.AUDIO.BANK:
			var new_data = data.duplicate()
			new_data['audio_path'] = [data['audio_path']]
			EventManager.editor_create_audio_keyframe.emit(new_data)
		LevelEditor.AUDIO.MUSIC:
			if Config.asset["song_path"] == filename.text: return
			Config.asset["song_path"] = filename.text
			music.set_editor_music()
		LevelEditor.AUDIO.HORNY:
			if Config.asset["horny_mode_sound"] == filename.text: return
			Config.asset["horny_mode_sound"] = filename.text
	
	if id == 5:
		DirAccess.remove_absolute(Editor.project_path + "audio/" + filename.text)
		file_drop.reload_file_list_audio()
		Util.free_node(self)
	
	Editor.level_changed = true
