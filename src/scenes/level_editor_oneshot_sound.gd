extends AudioStreamPlayer

@onready var tsevent: TSEvent = TSEvent.new()

func _ready():
	tsevent.callback = play_sound
	tsevent.config_key = "sound_oneshot"
	add_child(tsevent)

func play_sound(idx: int):
	if idx >= 0 and tsevent.index > tsevent.last_index:
		stop(); stream = Assets.get_asset(Config.keyframes['sound_oneshot'][idx]['path'])
		play()
