extends Button

func _on_level_editor_menu_visibility_changed():
	if Cutscene.exists(Cutscene.PRE) or Cutscene.exists(Cutscene.POST):
		text = "Go to Cutscene Editor"
	else:
		text = "Create Cutscene"

func _on_button_up():
	var dir = DirAccess.open(Editor.project_path)
	if not dir.dir_exists("cutscene"):
		Cutscene.type = 0
		LevelCreator.create_cutscene()
	
	Editor.controls_enabled = true
	get_tree().change_scene_to_file("res://src/scenes/cutscene_editor.tscn")
