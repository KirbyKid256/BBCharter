extends TextureRect

@onready var tsevent: TSEvent = TSEvent.new()

var data: Dictionary

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	
	tsevent.callback = change_background
	tsevent.config_key = "background"
	add_child(tsevent)
	
	if Editor.project_loaded: change_background(tsevent.index)

func _on_editor_project_loaded():
	set_texture(null)

func change_background(idx: int):
	if Config.keyframes['background'].is_empty() or idx < 0: set_texture(null); return
	
	data = Config.keyframes['background'][idx]
	
	set_texture(Assets.get_asset(data['path']))
	expand_mode = data.get('expand_mode', EXPAND_IGNORE_SIZE)
	stretch_mode = data.get('stretch_mode', STRETCH_KEEP_ASPECT_COVERED)
