extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	var tsevent: TSEvent = TSEvent.new()
	tsevent.callback = run_shutter
	tsevent.config_key = "shutter"
	add_child(tsevent)

func run_shutter(_idx: int):
	animation_player.stop()
	animation_player.play("shutter")
