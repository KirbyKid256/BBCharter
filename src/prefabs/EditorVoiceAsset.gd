extends Control

enum {EDIT,DELETE}

@onready var icon: Sprite2D = $Icon
@onready var file_list: Label = $FileListPrev
@onready var context_menu: PopupMenu = $ContextMenu

var data: Dictionary

func setup(keyframe_data: Dictionary):
	data = keyframe_data
	file_list.text = str(data['audio_path']).replace("[", "").replace("]", "").replace("\"", "")
	tooltip_text = file_list.text.replace(", ", "\r\n")

func _on_mouse_entered():
	icon.modulate.a = 1
	file_list.modulate.a = 1

func _on_mouse_exited():
	icon.modulate.a = 0.5
	file_list.modulate.a = 0.5

func _on_gui_input(event: InputEvent):
	if EventManager.left_mouse_clicked(event):
		EventManager.editor_try_add_voicebank.emit(data)
	elif EventManager.right_mouse_clicked(event):
		context_menu.set_position(position + event.position)
		context_menu.popup()

func _on_context_menu_id_pressed(id: int):
	match id:
		EDIT: EventManager.editor_create_audio_keyframe.emit(data, true)
		DELETE:
			LevelEditor.remove_asset_cache(data)
			Util.free_node(self)
