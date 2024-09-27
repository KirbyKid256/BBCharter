extends Control

@onready var music: LevelEditorMusic = $"../../../../../Music"
@onready var file_drop: Control = $"../../../../../FileDrop"
@onready var final_video: VideoStreamPlayer = $"../../../../../Preview/FinalVideo"
@onready var final_video_thumbnail: TextureRect = $"../../../../Cache/Misc/Grid/Climax/Thumbnail"
@onready var final_audio: AudioStreamPlayer = $"../../../../../Preview/FinalVideo/Audio"

@onready var filename: Label = $Filename
@onready var level_editor_icon: Sprite2D = $LevelEditorIcon

@onready var context_menu_image: PopupMenu = $ContextMenuImage
@onready var context_menu_audio: PopupMenu = $ContextMenuAudio
@onready var context_menu_video: PopupMenu = $ContextMenuVideo

var data: Dictionary

func setup(file_data):
	data = file_data
	if data.has("sprite_sheet"):
		filename.text = data["sprite_sheet"]
		level_editor_icon.texture = preload("res://assets/ui/level_editor_icon_image.png")
	elif data.has("audio_path"):
		filename.text = data["audio_path"]
		level_editor_icon.texture = preload("res://assets/ui/level_editor_icon_audio.png")
	elif data.has("video_path"):
		filename.text = data["video_path"]
		level_editor_icon.texture = preload("res://assets/ui/level_editor_icon_video.png")
	tooltip_text = filename.text

func _on_mouse_entered():
	level_editor_icon.modulate.a = 1.0

func _on_mouse_exited():
	level_editor_icon.modulate.a = 0.3

func _on_gui_input(event: InputEvent):
	if data.has("sprite_sheet"):
		if EventManager.left_mouse_clicked(event):
			EventManager.editor_create_image_keyframe.emit(data, LevelEditor.IMAGE.ANIMATION)
		elif EventManager.right_mouse_clicked(event):
			context_menu_image.set_position(global_position + event.position)
			context_menu_image.popup()
	elif data.has("audio_path"):
		if EventManager.left_mouse_clicked(event):
			EventManager.editor_try_add_oneshot.emit(data)
		elif EventManager.right_mouse_clicked(event):
			context_menu_audio.set_position(global_position + event.position)
			context_menu_audio.popup()
	elif data.has("video_path"):
		if EventManager.left_mouse_clicked(event):
			final_video.preview(filename.text, false)
		elif EventManager.right_mouse_clicked(event):
			context_menu_video.set_position(global_position + event.position)
			context_menu_video.popup()

func _on_context_menu_image_id_pressed(id):
	EventManager.editor_create_image_keyframe.emit(data, id)

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
			Editor.level_changed = true
		LevelEditor.AUDIO.FINAL:
			final_video.stop(); final_audio.stop()
			Config.asset["final_audio"] = filename.text
			Editor.level_changed = true
		LevelEditor.AUDIO.HORNY:
			Config.asset["horny_mode_sound"] = filename.text
			Editor.level_changed = true

func _on_context_menu_video_id_pressed(id):
	match id:
		LevelEditor.VIDEO.PREVIEW:
			final_video.preview(filename.text, false)
		LevelEditor.VIDEO.FINAL:
			final_video.stop(); final_audio.stop()
			Config.asset["final_video"] = filename.text
			final_video_thumbnail.texture = final_video.get_thumbnail()
			Editor.level_changed = true
