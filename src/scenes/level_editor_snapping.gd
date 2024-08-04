extends OptionButton

@onready var toggle_button: Button = $Toggle

var snap_values: Array = [1,2,3,4,6,8]

func _ready():
	await get_tree().process_frame
	# Set selected item in option box
	selected = LevelEditor.snapping_index
	_on_item_selected(selected)

func _on_item_selected(index):
	LevelEditor.snapping_index = index
	LevelEditor.snapping_factor = snap_values[index]
	Console.log({"message": 'Snapping factor set to 1/%s' % LevelEditor.snapping_factor})
	EventManager.editor_update_snapping.emit(index)

func _on_snapping_toggled(toggled_on):
	LevelEditor.snapping_allowed = toggled_on
	toggle_button.text = "ON" if toggled_on else "OFF"
	Console.log({"message": 'Snapping factor toggled %s' % toggle_button.text})
