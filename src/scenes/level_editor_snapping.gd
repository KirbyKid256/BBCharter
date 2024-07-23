extends OptionButton

@onready var toggle_button: Button = $Toggle

var snap_values: Array = [1,2,3,4,6,8]

func _ready():
	await get_tree().process_frame
	_on_item_selected(LevelEditor.snapping_index)
	# Set selected item in option box
	selected = snap_values.find(LevelEditor.snapping_factor) 

func _on_item_selected(index):
	LevelEditor.snapping_index = index
	LevelEditor.snapping_factor = snap_values[index]
	Console.log({"message": 'Snapping factor set to 1/%s' % LevelEditor.snapping_factor})
	EventManager.emit_signal('editor_update_snapping', index)

func _on_snapping_toggled(toggled_on):
	LevelEditor.snapping_allowed = toggled_on
	toggle_button.text = "ON" if toggled_on else "OFF"
	Console.log({"message": 'Snapping factor toggled %s' % toggle_button.text})
