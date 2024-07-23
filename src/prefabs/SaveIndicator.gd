extends Node2D
class_name SaveIndicator

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func show_saved_succes():
	animation_player.stop()
	animation_player.play("show_save_ui")
