extends Control

@onready var act_name_field: LineEdit = $Settings/HBoxContainer/ActNameField
@onready var act_description_field: TextEdit = $Settings/ActDescriptionField
@onready var act_index_field: SpinBox = $Settings/HBoxContainer2/ActIndexField
@onready var act_legacy: Button = $Settings/HBoxContainer3/ActLegacyField

@onready var top_bar: Polygon2D = $"../../Preview/TopBar"
@onready var legacy_bars: Node2D = $"../../Preview/Legacy"

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)

func _on_editor_level_loaded():
	legacy_bars.visible = Config.act.get('is_legacy', false)
	top_bar.visible = not legacy_bars.visible

func _input(event):
	if MenuCache.menu_disabled(self): return
	if event.is_action("ui_cancel"): hide()

func _on_act_settings_button_up():
	if Config.act.is_empty(): LevelCreator.create_act_config()
	
	act_name_field.text = Config.act.get('act_name', "My Act")
	act_description_field.text = Config.act.get('act_description', "My Description")
	act_index_field.value = Config.act.get('act_index', 0)
	act_legacy.set_pressed(Config.act.get('is_legacy', false))
	
	show()

func _on_act_legacy_field_toggled(toggled_on):
	act_legacy.text = "ON" if toggled_on else "OFF"

func _on_save_button_up():
	Config.act['act_name'] = act_name_field.text
	Config.act['act_description'] = act_description_field.text
	Config.act['act_index'] = int(act_index_field.value)
	
	if act_legacy.button_pressed: Config.act['is_legacy'] = true
	else: Config.act.erase('is_legacy')
	_on_editor_level_loaded()
	
	Editor.project_changed = true
	LevelEditor.controls_enabled = true
	hide()
