extends Control

@onready var cutscene_editor_panels = $CutsceneEditorPanels
@onready var preview_image = $CutsceneEditorPreview/Panel/PreviewImage
@onready var dialogue_field = $CutsceneEditorControls/DialogueField
@onready var character_field = $CutsceneEditorControls/CharacterField

var menu_manager: Menu

func _ready():
	Global.save_indicator = $SaveIndicator
	Global.error_notification = $ErrorNotification
	Global.editor_menu = $MenuOverlays/CutsceneEditorMenu
	
	EventManager.cutscene_loaded.connect(_on_cutscene_loaded)
	get_viewport().files_dropped.connect(cutscene_editor_panels._on_files_dropped)
	
	menu_manager = Menu.new()
	menu_manager.root = cutscene_editor_panels
	menu_manager.margin = 400
	menu_manager.scales = [0.85,0.9]
	menu_manager.highlight = true
	menu_manager.index = Cutscene.index
	menu_manager.menu_updated.connect(_on_menu_updated)
	add_child(menu_manager)
	
	CutsceneEditor.load_pre_script()
	CutsceneEditor.load_post_script()
	
	EventManager.cutscene_loaded.emit()
	EventManager.cutscene_panel_changed.emit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Global.editor_menu.toggle()
	
	if not Editor.controls_enabled: return
	
	if event.is_action_pressed("ui_editor_save"):
		CutsceneEditor.save_scripts()
		Global.save_indicator.show_saved_succes()
	
	if event.is_action_pressed("editor_view_files"):
		OS.shell_open(Editor.project_path + "cutscene")

func _on_cutscene_loaded():
	Cutscene.index = 0
	menu_manager.index = 0
	load_panels()

func load_panels():
	await cutscene_editor_panels.reload_panels()
	menu_manager.register_items(cutscene_editor_panels.get_children())

func _on_menu_updated(selected_item):
	Cutscene.index = selected_item.get_index()
	
	#Populate Fields
	preview_image.texture = Cutscene.get_image(CutsceneEditor.get_current_panel().get("src", ""))
	dialogue_field.text = CutsceneEditor.get_current_panel().get("dialogue", "")
	character_field.text = CutsceneEditor.get_current_panel().get("character", "")
	
	EventManager.cutscene_panel_changed.emit()

func _on_character_field_text_submitted(new_text):
	CutsceneEditor.get_current_panel()["character"] = new_text
	menu_manager.selected_item.update_visuals()
	Editor.cutscene_changed = true

func _on_dialogue_field_text_changed():
	CutsceneEditor.get_current_panel()["dialogue"] = dialogue_field.text
	menu_manager.selected_item.dialogue.text = dialogue_field.text
	Editor.cutscene_changed = true

func _on_insert_shot_button_up():
	var current_panel_index = CutsceneEditor.data[Cutscene.type].lines.find(CutsceneEditor.get_current_panel())
	
	var default_panel = {
		"character": "Character", 
		"dialogue": "sample text..."
	}
	
	CutsceneEditor.data[Cutscene.type].lines.insert(current_panel_index+1, default_panel)
	Editor.cutscene_changed = true
	load_panels()

func _on_delete_shot_button_up():
	var current_panel_index = CutsceneEditor.data[Cutscene.type].lines.find(CutsceneEditor.get_current_panel())
	CutsceneEditor.data[Cutscene.type].lines.remove_at(current_panel_index)
	Editor.cutscene_changed = true
	load_panels()

func _on_pre_post_button_up():
	Cutscene.type = int(not bool(Cutscene.type))
	if not DirAccess.dir_exists_absolute(Editor.project_path + "cutscene/%s" % ["pre","post"][Cutscene.type]):
		LevelCreator.create_cutscene()
	
	EventManager.cutscene_loaded.emit()
	EventManager.cutscene_panel_changed.emit()
	Global.editor_menu.toggle()
