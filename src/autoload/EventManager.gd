extends Node

# Global Signals
signal console_logged(message: String)
signal editor_project_loaded()

# Cutscene signals
signal cutscene_loaded()
signal cutscene_panel_changed()
signal cutscene_ended()

# Level Signals
signal editor_note_hit(note_object: Dictionary)
signal editor_note_miss(note_object: Dictionary)
signal editor_note_created(new_editor_note_data: Dictionary)
signal editor_update_snapping(snap_index: int)
signal editor_update_notespeed()
signal editor_update_bpm()
signal editor_create_image_keyframe(data: Dictionary, type: int)
signal editor_create_audio_keyframe(data: Dictionary)
signal editor_try_add_animation(image_data: Dictionary)
signal editor_try_add_effect(image_data: Dictionary)
signal editor_try_add_background(image_data: Dictionary)
signal editor_try_add_oneshot(audio_data: Dictionary)
signal editor_try_add_loopsound(audio_data: Dictionary)
signal editor_try_add_voicebank(audio_data: Dictionary)

func left_mouse_clicked(event: InputEvent) -> bool:
	if not event is InputEventMouseButton: return false
	if not event.button_index == MOUSE_BUTTON_MASK_LEFT: return false
	if not event.pressed: return false
	return true

func right_mouse_clicked(event: InputEvent) -> bool:
	if not event is InputEventMouseButton: return false
	if not event.button_index == MOUSE_BUTTON_MASK_RIGHT: return false
	if not event.pressed: return false
	return true
