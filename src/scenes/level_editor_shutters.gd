extends Node2D

@onready var tsevent: TSEvent = TSEvent.new()
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	tsevent.callback = run_shutter
	tsevent.config_key = "shutter"
	add_child(tsevent)
	
	animation_player.play("shutter")
	animation_player.seek(0.5)

func run_shutter(_idx: int):
	if tsevent.index > tsevent.last_index:
		animation_player.play("shutter")
