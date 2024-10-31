extends Control

@export var editor_file_asset_prefab: PackedScene

@onready var asset_grid: VBoxContainer = $ScrollContainer/AssetGrid
@onready var menu_bar: MenuBar = $"../../MenuBar"

func _ready():
	EventManager.editor_project_loaded.connect(get_files)
	
	if menu_bar.is_native_menu():
		asset_grid.get_parent().position.y -= 40
		asset_grid.get_parent().size.y += 40
	
	if Editor.project_loaded: get_files()

func get_files():
	Util.clear_children(asset_grid)
	Console.log({"message": "Getting Files in Level Folder..."})
	
	for image in DirAccess.get_files_at(Editor.project_path + "images"):
		if image.get_extension() == "png" or image.get_extension() == "jpg" or image.get_extension() == "jpeg" or image.get_extension() == "webp":
			var new_image_asset_node = editor_file_asset_prefab.instantiate() as Control
			asset_grid.add_child(new_image_asset_node) 
			new_image_asset_node.setup({"sprite_sheet": image})
	
	for audio in DirAccess.get_files_at(Editor.project_path + "audio"):
		if audio.get_extension() == "ogg" or audio.get_extension() == "mp3":
			var new_audio_asset_node = editor_file_asset_prefab.instantiate() as Control
			asset_grid.add_child(new_audio_asset_node) 
			new_audio_asset_node.setup({"audio_path": audio})
	
	for video in DirAccess.get_files_at(Editor.project_path + "video"):
		if video.get_extension() == "ogv":
			var new_video_asset_node = editor_file_asset_prefab.instantiate() as Control
			asset_grid.add_child(new_video_asset_node) 
			new_video_asset_node.setup({"video_path": video})
		elif ClassDB.class_exists("VideoStreamFFmpeg") and (video.get_extension() == "webm" or video.get_extension() == "mp4" or video.get_extension() == "mov"):
			var new_video_asset_node = editor_file_asset_prefab.instantiate() as Control
			asset_grid.add_child(new_video_asset_node) 
			new_video_asset_node.setup({"video_path": video})
