extends AudioStreamPlayer

func _ready():
	var tsevent = TSEvent.new()
	tsevent.callback = play_sound
	tsevent.config_key = "sound_oneshot"
	add_child(tsevent)

func play_sound(idx: int):
	stop()
	stream = Assets.get_asset(Config.keyframes['sound_oneshot'][idx]['path'])
	play()
