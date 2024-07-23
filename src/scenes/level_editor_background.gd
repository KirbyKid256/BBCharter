extends TextureRect

@onready var tsevent = TSEvent.new()

var data: Dictionary

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)
	
	tsevent.callback = change_background
	tsevent.config_key = "background"
	add_child(tsevent)

func _on_editor_level_loaded():
	change_background(0)

func change_background(idx: int):
	if Config.keyframes['background'].is_empty(): set_texture(null); return
	data = Config.keyframes['background'][idx]
	
	set_texture(Assets.get_asset(data['path']))
	expand_mode = data.get('expand_mode', EXPAND_IGNORE_SIZE)
	stretch_mode = data.get('expand_mode', STRETCH_KEEP_ASPECT_COVERED)
