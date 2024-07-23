extends Control

enum {EDIT,DELETE}

@onready var filename_label: Label = $FilenameLabel
@onready var sprite_sheet: Sprite2D = $SpriteSheet
@onready var context_menu: PopupMenu = $ContextMenu

var data: Dictionary
var preview_frame_value: float = 0.0
var hovering: bool

func setup(keyframe_data: Dictionary):
	data = keyframe_data
	var filename: String = data['sprite_sheet']
	filename_label.text = filename
	
	sprite_sheet.texture = Assets.get_asset(filename)
	sprite_sheet.set_vframes(data['sheet_data'].v)
	sprite_sheet.set_hframes(data['sheet_data'].h)
	sprite_sheet.scale = Vector2(data.get('scale_multiplier', 1.0) * 0.188,
	data.get('scale_multiplier', 1.0) * 0.188)
	
	tooltip_text = str(data).replace(", ", "\r\n")\
	.replace("{", "").replace("}", "").replace("\"", "")

func _on_mouse_entered():
	filename_label.hide()
	sprite_sheet.modulate.a = 1.0
	hovering = true

func _on_mouse_exited():
	filename_label.show()
	sprite_sheet.modulate.a = 0.2
	hovering = false

func _process(delta: float):
	if hovering:
		preview_frame_value = wrapf(preview_frame_value + 0.075, 0.0 ,float(data['sheet_data'].total))
		sprite_sheet.frame = int(preview_frame_value)

func _on_gui_input(event: InputEvent):
	if EventManager.left_mouse_clicked(event):
		EventManager.editor_try_add_animation.emit(data)
	elif EventManager.right_mouse_clicked(event):
		context_menu.set_position(position + event.position)
		context_menu.popup()

func _on_context_menu_id_pressed(id: int):
	match id:
		EDIT: EventManager.editor_create_image_keyframe.emit(data, LevelEditor.IMAGE.ANIMATION, true)
		DELETE:
			LevelEditor.remove_asset_cache(data)
			Util.free_node(self)
