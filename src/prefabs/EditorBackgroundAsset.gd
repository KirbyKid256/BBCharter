extends Control

enum {EDIT,DELETE}

@onready var filename_label: Label = $FilenameLabel
@onready var texture_rect: TextureRect = $TextureRect
@onready var context_menu: PopupMenu = $ContextMenu

var data: Dictionary

func _ready():
	get_viewport().files_dropped.connect(_on_files_dropped)

func setup(keyframe_data: Dictionary):
	data = keyframe_data
	var filename: String = data['sprite_sheet']
	filename_label.text = filename
	
	texture_rect.texture = Assets.get_asset(filename)
	texture_rect.expand_mode = data.get('expand_mode', TextureRect.EXPAND_IGNORE_SIZE)
	texture_rect.stretch_mode = data.get('stretch_mode', TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	
	tooltip_text = str(data).replace(", ", "\r\n")\
	.replace("{", "").replace("}", "").replace("\"", "")

func _on_files_dropped(files: PackedStringArray):
	texture_rect.texture = Assets.get_asset(filename_label.text)

func _on_mouse_entered():
	filename_label.hide()
	texture_rect.modulate.a = 1.0

func _on_mouse_exited():
	filename_label.show()
	texture_rect.modulate.a = 0.2

func _on_gui_input(event: InputEvent):
	if EventManager.left_mouse_clicked(event):
		EventManager.editor_try_add_background.emit(data)
	elif EventManager.right_mouse_clicked(event):
		context_menu.set_position(position + event.position)
		context_menu.popup()

func _on_context_menu_id_pressed(id: int):
	match id:
		EDIT: EventManager.editor_create_image_keyframe.emit(data, LevelEditor.IMAGE.BACKGROUND, true)
		DELETE:
			LevelEditor.remove_asset_cache(data)
			Util.free_node(self)
