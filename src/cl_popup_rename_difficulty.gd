extends Panel

func _ready():
	Events.popups_closed.connect(_on_popups_opened)
	Events.popups_closed.connect(_on_popups_closed)

func _on_popups_opened():
	if !Save.notes.is_empty():
		$DifficultyRatingField.max_value = Save.notes['charts'].size()-1
		$DifficultyNameField.placeholder_text = Save.notes['charts'][$DifficultyRatingField.value]['name']

func _on_value_changed(value):
	$DifficultyNameField.placeholder_text = Save.notes['charts'][value]['name']

func _on_rename_button_up() -> void:
	var difficulty_name = $DifficultyNameField.text
	var difficulty_rating = $DifficultyRatingField.value
	
	if Save.notes.is_empty(): return print('Error renaming difficulty')
	if !difficulty_name.is_valid_filename(): return print('Invalid Filename')
	
	Global.project_saved = false
	var old_name = Save.notes['charts'][difficulty_rating]['name']
	Save.notes['charts'][difficulty_rating]['name'] = difficulty_name
	Events.emit_signal('difficulty_renamed', [difficulty_rating, old_name])
	Popups.close()

func _on_cancel_button_up():
	Popups.close()

func _on_popups_closed():
	$DifficultyNameField.clear()
