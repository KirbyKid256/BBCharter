extends Node2D
class_name ErrorNotification

@onready var message_label: Label = $Root/MessageLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func show_error(message: String):
	animation_player.stop()
	animation_player.play("show_error")
	message_label.text = message
