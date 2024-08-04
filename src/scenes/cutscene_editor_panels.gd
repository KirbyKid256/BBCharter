extends Node2D

@export var cutscene_editor_panel_prefab: PackedScene

@onready var cutscene_editor = $".."
@onready var cutscene_editor_assets = $"../CutsceneEditorAssets"

func _ready():
	EventManager.cutscene_loaded.connect(reload_panels)

func reload_panels():
	Util.clear_children(self)
	
	for idx: int in CutsceneEditor.data[Cutscene.type].lines.size():
		var new_cutscene_panel = cutscene_editor_panel_prefab.instantiate() as Node2D
		add_child(new_cutscene_panel)
		new_cutscene_panel.update_visual()

func _on_files_dropped(files: PackedStringArray):
	for file in files:
		if ["png"].has(file.get_extension()): import_image(file)
		if ["ogg"].has(file.get_extension()): import_audio(file)

func import_image(image_file):
	DirAccess.copy_absolute(image_file, Cutscene.path() + "/shots/" + image_file.get_file())

func import_audio(audio_file):
	DirAccess.copy_absolute(audio_file, Cutscene.path() + "/audio/" + audio_file.get_file())
