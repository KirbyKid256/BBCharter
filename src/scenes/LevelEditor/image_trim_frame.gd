extends Control
class_name ImageTrimFrame

enum {
	SET_START = 1, 
	DELETE_BEFORE = 2, 
	DELETE_AFTER = 3
	}

@onready var image_trimmer: ImageTrimmer = $"../../.."
@onready var preview_animation: PreviewAnimation = $"../../../PreviewAnimation"

@onready var texture_rect: TextureRect = $TextureRect
@onready var index_label: Label = $IndexLabel
@onready var context_menu: PopupMenu = $ContextMenu

var index: int
var file_path: String
var image_texture: ImageTexture

func setup(_index: int, _file_path: String):
	index = _index
	file_path = _file_path
	image_texture = Files.load_image(file_path)
	texture_rect.texture = image_texture
	index_label.text = str(index)

func trim_frame_delete():
	DirAccess.remove_absolute(file_path)
	queue_free()

func _on_gui_input(event: InputEvent):
	if not event is InputEventMouseButton: return 
	if not event.pressed: return 
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			preview_animation.stop()
			preview_animation.frame = index - 1
		MOUSE_BUTTON_RIGHT:
			context_menu.position = get_global_mouse_position()
			context_menu.set_item_text(0, "Frame %s" % index_label.text)
			context_menu.popup()

func _on_context_menu_id_pressed(id: int):
	match id:
		SET_START: image_trimmer.set_start_frame(index)
		DELETE_BEFORE: image_trimmer.mass_delete(index, true)
		DELETE_AFTER: image_trimmer.mass_delete(index, false)
