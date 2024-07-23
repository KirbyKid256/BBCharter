extends Control

@export var editor_animation_asset_prefab: PackedScene
@export var editor_effect_asset_prefab: PackedScene
@export var editor_background_asset_prefab: PackedScene
@export var editor_voice_asset_prefab: PackedScene

@onready var animations_grid = $Animations/AssetGrid
@onready var effects_grid = $Effects/AssetGrid
@onready var backgrounds_grid = $Backgrounds/AssetGrid
@onready var voices_grid = $"Voice Banks/AssetGrid"

@onready var menu_bar: MenuBar = $"../../MenuBar"
@onready var menu_bar_panel: Panel = $"../MenuBarPanel"

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)
	
	if menu_bar.is_native_menu():
		menu_bar_panel.hide()
		position.y -= 40
		size.y += 40

func _on_editor_level_loaded():
	get_image_assets()
	get_audio_assets()

func get_image_assets(type: int = -1):
	Util.clear_children(animations_grid)
	Util.clear_children(effects_grid)
	Util.clear_children(backgrounds_grid)
	
	Console.log({"message": "Getting Editor Image Cache..."})
	var cache_assets = LevelEditor.get_asset_cache().filter(func(a): return a.has("sprite_sheet"))
	
	if type == LevelEditor.IMAGE.ANIMATION or type < 0:
		var animation_assets = cache_assets.filter(func(a): return a.has("sheet_data") and not a.has("duration"))
		for animation in animation_assets:
			var new_asset_node = editor_animation_asset_prefab.instantiate() as Control
			animations_grid.add_child(new_asset_node) 
			new_asset_node.setup(animation)
	
	if type == LevelEditor.IMAGE.EFFECT or type < 0:
		var effect_assets = cache_assets.filter(func(a): return a.has("duration"))
		for effect in effect_assets:
			var new_asset_node = editor_effect_asset_prefab.instantiate() as Control
			effects_grid.add_child(new_asset_node) 
			new_asset_node.setup(effect)
	
	if type == LevelEditor.IMAGE.BACKGROUND or type < 0:
		var background_assets = cache_assets.filter(func(a): return not a.has("sheet_data"))
		for background in background_assets:
			var new_asset_node = editor_background_asset_prefab.instantiate() as Control
			backgrounds_grid.add_child(new_asset_node) 
			new_asset_node.setup(background)

func get_audio_assets():
	Util.clear_children(voices_grid)
	
	Console.log({"message": "Getting Editor Audio Cache..."})
	var cache_assets = LevelEditor.get_asset_cache().filter(func(a): return a.has("audio_path"))
	
	var voice_assets = cache_assets.filter(func(a): return typeof(a['audio_path']) == TYPE_ARRAY)
	for animation in voice_assets:
		var new_asset_node = editor_voice_asset_prefab.instantiate() as Control
		voices_grid.add_child(new_asset_node) 
		new_asset_node.setup(animation)