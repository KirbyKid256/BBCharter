extends Panel

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if Editor.project_changed():
			Editor.controls_enabled = false
			show()
		else:
			get_tree().quit()

func _on_discard_button_up():
	get_tree().quit()

func _on_cancel_button_up():
	Editor.controls_enabled = true
	hide()

func _on_save_button_up():
	Editor.save_project()
	await get_tree().process_frame
	get_tree().quit()
