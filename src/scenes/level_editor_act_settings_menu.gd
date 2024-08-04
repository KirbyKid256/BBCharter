extends Control

@onready var act_name_field: LineEdit = $Settings/HBoxContainer/ActNameField
@onready var act_description_field: TextEdit = $Settings/ActDescriptionField
@onready var act_index_field: SpinBox = $Settings/HBoxContainer/ActIndexField
@onready var act_legacy: Button = $Settings/HBoxContainer2/ActLegacyField

@onready var thumb_select: Panel = $ThumbSelect
@onready var thumb_preview: TextureRect = $ThumbSelect/Preview
@onready var file_dialog: FileDialog = $"../FileDialog"

@onready var legacy_bars: Node2D = $"../../Preview/Legacy"

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	file_dialog.current_dir = Global.get_executable_path()

func _on_editor_project_loaded():
	legacy_bars.visible = Config.act.get('act_legacy', false)
	
	Assets.act_thumb = Files.load_image(Editor.project_path.get_base_dir().get_base_dir() + "/thumb.png")
	thumb_preview.texture = Assets.act_thumb

func _input(event):
	if not visible: return
	if event.is_action("ui_cancel"): hide()

func text_focused() -> bool:
	return act_name_field.has_focus() or act_description_field.has_focus() or act_index_field.has_focus()

func _on_act_settings_button_up():
	if Config.act.is_empty():
		LevelCreator.create_act_config()
		LevelCreator.create_act_placeholders()
		
		Assets.act_thumb = Files.load_image(Editor.project_path.get_base_dir().get_base_dir() + "/thumb.png")
		thumb_preview.texture = Assets.act_thumb
	
	act_name_field.text = Config.act.get('act_name', "My Act")
	act_description_field.text = Config.act.get('act_description', "My Description")
	act_index_field.value = Config.act.get('act_index', 0)
	act_legacy.set_pressed(Config.act.get('act_legacy', false))
	
	show()

func _on_act_legacy_field_toggled(toggled_on):
	act_legacy.text = "ON" if toggled_on else "OFF"

func _on_thumb_select_mouse_entered():
	thumb_select.self_modulate = Color.WHITE

func _on_thumb_select_mouse_exited():
	thumb_select.self_modulate = Color8(255, 255, 255, 95)

func _on_file_dialog_file_selected(path):
	if not visible: return
	
	var thumb: String = Editor.project_path.get_base_dir().get_base_dir().path_join("thumb.png")
	DirAccess.copy_absolute(path, thumb)
	
	Assets.act_thumb = Files.load_image(thumb)
	thumb_preview.texture = Assets.act_thumb

func _on_save_button_up():
	Config.act['act_name'] = act_name_field.text
	Config.act['act_description'] = act_description_field.text
	Config.act['act_index'] = int(act_index_field.value)
	
	if act_legacy.button_pressed: Config.act['act_legacy'] = true
	else: Config.act.erase('act_legacy')
	_on_editor_project_loaded()
	
	Editor.level_changed = true
	Editor.controls_enabled = true
	hide()
