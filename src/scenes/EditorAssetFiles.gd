extends Control

@export var editor_file_asset_prefab: PackedScene

@onready var asset_grid: VBoxContainer = $ScrollContainer/AssetGrid
@onready var menu_bar: MenuBar = $"../../MenuBar"

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)
	
	if menu_bar.is_native_menu():
		asset_grid.get_parent().position.y -= 40
		asset_grid.get_parent().size.y += 40

func _on_editor_level_loaded():
	get_files()

func get_files():
	for child in asset_grid.get_children(): child.queue_free()
	Console.log({"message": "Getting Files in Level Folder..."})
	
	for image in DirAccess.get_files_at(Editor.level_path + "images"):
		if image.get_extension() == "png" or image.get_extension() == "jpg" or image.get_extension() == "jpeg":
			var new_image_asset_node = editor_file_asset_prefab.instantiate() as Control
			asset_grid.add_child(new_image_asset_node) 
			new_image_asset_node.setup({"sprite_sheet": image})
	
	for audio in DirAccess.get_files_at(Editor.level_path + "audio"):
		if audio.get_extension() == "ogg" or audio.get_extension() == "mp3":
			var new_audio_asset_node = editor_file_asset_prefab.instantiate() as Control
			asset_grid.add_child(new_audio_asset_node) 
			new_audio_asset_node.setup({"audio_path": audio})
