extends TextureRect

var data: Dictionary

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)
	
	var tsevent = TSEvent.new()
	tsevent.callback = change_background
	tsevent.config_key = "background"
	add_child(tsevent)

func _on_editor_level_loaded():
	set_texture(null)

func change_background(idx: int):
	if Config.keyframes['background'].is_empty() or idx < 0: set_texture(null); return
	
	data = Config.keyframes['background'][idx]
	
	set_texture(Assets.get_asset(data['path']))
	expand_mode = data.get('expand_mode', EXPAND_IGNORE_SIZE)
	stretch_mode = data.get('stretch_mode', STRETCH_KEEP_ASPECT_COVERED)
