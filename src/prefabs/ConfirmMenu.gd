extends Panel

var close_signal: Callable

func _notification(what):
	if visible: return
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if Editor.project_changed():
			close_signal = get_tree().quit
			open()
		else:
			get_tree().quit()

func open():
	Editor.controls_enabled = false
	show()

func close():
	Editor.controls_enabled = true
	hide()

func _on_discard_button_up():
	close_signal.call()
	close()

func _on_cancel_button_up():
	close()

func _on_save_button_up():
	Editor.save_project()
	await get_tree().process_frame
	close_signal.call()
	close()
