extends TextureRect

@onready var tsevent: TSEvent = TSEvent.new()
@onready var pattern: Sprite2D = $Pattern

var data: Dictionary

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	
	tsevent.callback = change_background
	tsevent.config_key = "background"
	add_child(tsevent)
	
	if Editor.project_loaded: change_background(tsevent.index)

func _on_editor_project_loaded():
	change_background(0)

func change_background(idx: int):
	if Config.keyframes.background.is_empty():
		texture = null
		pattern.hide()
		return
	
	idx = clampi(idx,0,Config.keyframes.background.size()-1)
	data = Config.keyframes.background[idx]
	
	if data.has("type") and (data.type == 1 or data.type == 2):
		if data.type == 1:
			pattern.hide()
			texture = null
		elif data.type == 2:
			pattern.texture = Assets.get_asset(data.path)
			pattern.show()
	else:
		pattern.hide()
		texture = Assets.get_asset(data.path)
		expand_mode = EXPAND_KEEP_SIZE
		stretch_mode = STRETCH_SCALE
