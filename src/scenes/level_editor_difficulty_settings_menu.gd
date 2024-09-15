extends Control

@export var difficulty_asset: PackedScene

@onready var difficulties: VBoxContainer = $Difficulties/VBoxContainer
@onready var difficulty_select: OptionButton = $"../../TimelineInfo/DifficultySelect"
@onready var add_button: Button = $Difficulties/VBoxContainer/AddButton

@onready var name_field: LineEdit = $Settings/HBoxContainer2/NameField
@onready var speed_field: OptionButton = $Settings/HBoxContainer2/SpeedField
@onready var duplicate_label: Label = $Settings/Label
@onready var duplicate_field: OptionButton = $Settings/DuplicateField
@onready var file_selection: ScrollContainer = $Settings/FileSelection

var total_data: Array
var selected: int

func _ready():
	file_selection.button_up.connect(_on_file_button_up)

func _input(event):
	if not visible: return
	if event.is_action("ui_cancel"): hide()

func _on_difficulty_settings_button_up():
	file_selection.reload_list()
	duplicate_field.clear()
	duplicate_field.add_item("- Don't Copy Notes -")
	
	for child: Control in difficulties.get_children():
		if child is Button: continue # Don't touch the Add button
		difficulties.remove_child(child)
		child.queue_free()
	
	Editor.controls_enabled = false
	total_data = Config.notes['charts'].duplicate(true)
	
	for data in total_data:
		var difficulty = difficulty_asset.instantiate()
		difficulties.add_child(difficulty)
		difficulty.setup(data)
		difficulty.selected.connect(_on_difficulty_selected)
		
		if not data.notes.is_empty():
			duplicate_field.add_item(data.name, data.rating)
	
	difficulties.move_child(add_button, total_data.size())
	_on_difficulty_selected(LevelEditor.difficulty_index)
	show()

func _on_difficulty_selected(idx: int):
	if not difficulties.get_child(selected) is Button and difficulties.get_child(selected) != null:
		difficulties.get_child(selected).outline.hide()
	
	selected = clampi(idx,0,total_data.size()-1)
	if selected >= 0:
		difficulties.get_child(selected).outline.show()
		name_field.text = total_data[selected].name
		speed_field.selected = total_data[selected].get('speed', 0)
	
	duplicate_label.set_visible(total_data[selected].notes.is_empty())
	duplicate_field.set_visible(total_data[selected].notes.is_empty())

func _on_add_button_up():
	var new_data = {"name": "Normal", "notes": []}
	total_data.append(new_data)
	
	var difficulty = difficulty_asset.instantiate()
	difficulties.add_child(difficulty)
	difficulty.setup(new_data)
	difficulty.selected.connect(_on_difficulty_selected)
	
	difficulties.move_child(difficulty, total_data.size()-1)
	_on_difficulty_selected(total_data.size()-1)

func _on_name_field_mouse_entered():
	name_field.focus_mode = FOCUS_ALL
	name_field.grab_click_focus()

func _on_name_field_mouse_exited():
	name_field.focus_mode = FOCUS_NONE

func _on_name_field_text_submitted(new_text):
	total_data[selected].name = new_text
	difficulties.get_child(selected).difficulty_name.text = new_text

func _on_duplicate_field_item_selected(index):
	if index > 0:
		total_data[selected].duplicate = duplicate_field.get_item_id(index)
	else:
		total_data[selected].erase('duplicate')

func _on_speed_field_item_selected(index):
	if index > 0:
		total_data[selected].speed = index
	else:
		total_data[selected].erase('speed')

func _on_file_button_up(text):
	total_data[selected].icon = text
	difficulties.get_child(selected).icon.texture = Assets.get_asset(text)

func _on_save_button_up():
	for data in total_data:
		var arr: Array = total_data.filter(func(a): return a.name == data.name)
		if arr.size() > 1:
			Console.log({"message": "Difficulty names can't match!", "type": 2})
			return
	
	for i in total_data.size():
		if total_data[i].name == Difficulty.get_current_chart_value("name"):
			LevelEditor.difficulty_index = i
			break
	for i in total_data.size():
		total_data[i].rating = i
		if total_data[i].has('duplicate'):
			total_data[i].notes = Config.notes['charts'][total_data[i].duplicate].notes.duplicate(true)
			total_data[i].erase('duplicate')
	
	Config.notes['charts'] = total_data
	difficulty_select.disabled = true
	difficulty_select.reload_items()
	difficulty_select.disabled = false
	
	Editor.level_changed = true
	Editor.controls_enabled = true
	hide()
