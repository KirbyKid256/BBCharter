extends Sprite2D

@onready var tsevent = TSEvent.new()

var data: Dictionary
var tween: Tween

func _ready():
	tsevent.callback = play_effect
	tsevent.config_key = "effects"
	add_child(tsevent)

func play_effect(idx: int):
	if Config.keyframes['effects'].is_empty(): set_texture(null); return
	data = Config.keyframes['effects'][idx]
	
	set_hframes(data['sheet_data'].h)
	set_vframes(data['sheet_data'].v)
	set_texture(Assets.get_asset(data['path']))
	
	if tween: tween.kill() # Abort the previous animation.
	tween = get_tree().create_tween()
	tween.finished.connect(_on_tween_finished)
	set_frame(0)
	tween.tween_property(self, 'frame', data['sheet_data'].total-1, data['duration'])

func _on_tween_finished():
	texture = null
