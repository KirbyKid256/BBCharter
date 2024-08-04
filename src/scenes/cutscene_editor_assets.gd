extends Control

@export var audio_asset_prefab: PackedScene

@onready var cutscene_editor = $".."

@onready var audio_asset_container = $Tabs/Audio/VBoxContainer
@onready var add_audio_button = $Tabs/Audio/VBoxContainer/AddButton

func _ready():
	EventManager.cutscene_panel_changed.connect(reload_audio_assets)
	#shots_asset_containter.button_up.connect(_on_shots_button_up)
	#shots_asset_containter.reload_list()

func reload_audio_assets():
	for child in audio_asset_container.get_children():
		if not child is Button: child.queue_free()
	
	for idx in CutsceneEditor.get_current_panel().get("audio", []).size():
		var new_audio_asset = audio_asset_prefab.instantiate() as Control
		new_audio_asset.index = idx
		audio_asset_container.add_child(new_audio_asset)
	
	audio_asset_container.move_child(add_audio_button, audio_asset_container.get_child_count()-1)

func _on_add_audio_button_up():
	CutsceneEditor.get_current_panel().get("audio", []).append({"path": "audio.ogg"})
	
	var new_audio_asset = audio_asset_prefab.instantiate() as Control
	new_audio_asset.index = CutsceneEditor.get_current_panel().get("audio", []).size()-1
	audio_asset_container.add_child(new_audio_asset)
	
	audio_asset_container.move_child(add_audio_button, new_audio_asset.index + 1)

#func _on_shots_button_up(file: String):
	#CutsceneEditor.get_current_panel()["src"] = file.get_file()
	#cutscene_editor.menu_manager.refresh()
	#cutscene_editor.cutscene_editor_panels.get_child(Cutscene.index).update_visual()
