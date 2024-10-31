extends HSlider
class_name ImageTrimmerFrameSlider

@onready var preview_animation: PreviewAnimation = $"../PreviewAnimation"
@onready var frame_indicator: Label = $"../FrameIndicator"

func setup_slider():
	max_value = preview_animation.sprite_frames.get_frame_count(&"default") - 1

func _process(delta: float):
	if preview_animation.is_playing():
		value = preview_animation.frame

func _on_value_changed(v: float):
	var target_frame = ceili(v)
	preview_animation.frame = target_frame
	frame_indicator.text = "%s : %s" % [preview_animation.frame + 1, max_value + 1]

func _on_drag_started():
	preview_animation.pause()
