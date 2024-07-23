extends Control

@onready var difficulty_settings = $"../../../"

@onready var icon: Sprite2D = $Icon
@onready var difficulty_name: Label = $DifficultyName
@onready var note_count: Label = $NoteCount

@onready var up_button: TextureButton = $UpButton
@onready var down_button: TextureButton = $DownButton

@onready var outline: Panel = $Outline

var data: Dictionary

signal selected(idx: int)

func setup(chart_data: Dictionary):
	data = chart_data
	
	icon.texture = Assets.get_asset(data.get('icon', ''))
	if icon.texture == null: data.erase('icon')
	difficulty_name.text = data['name']
	note_count.text = "%s Notes" % data.get('notes', []).size()

func _on_mouse_entered():
	icon.modulate.a = 1
	difficulty_name.modulate.a = 1
	note_count.modulate.a = 1

func _on_mouse_exited():
	icon.modulate.a = 0.5
	difficulty_name.modulate.a = 0.5
	note_count.modulate.a = 0.5

func _on_up_button_mouse_entered():
	up_button.modulate.a = 1.0
func _on_up_button_mouse_exited():
	up_button.modulate.a = 0.3

func _on_down_button_mouse_entered():
	down_button.modulate.a = 1.0
func _on_down_button_mouse_exited():
	down_button.modulate.a = 0.3

func _on_up_button_up():
	var idx = get_index()
	var new_idx = clampi(idx-1,0,difficulty_settings.total_data.size()-1)
	
	difficulty_settings.total_data.remove_at(idx)
	difficulty_settings.total_data.insert(new_idx, data)
	
	difficulty_settings.difficulties.move_child(self, new_idx)
	selected.emit(new_idx)

func _on_down_button_up():
	var idx = get_index()
	var new_idx = clampi(idx+1,0,difficulty_settings.total_data.size()-1)
	
	difficulty_settings.total_data.remove_at(idx)
	difficulty_settings.total_data.insert(new_idx, data)
	
	difficulty_settings.difficulties.move_child(self, new_idx)
	selected.emit(new_idx)

func _on_gui_input(event: InputEvent):
	var idx = get_index()
	
	if EventManager.left_mouse_clicked(event):
		selected.emit(idx)
	elif EventManager.right_mouse_clicked(event):
		difficulty_settings.total_data.remove_at(idx)
		Util.free_node(self)
		selected.emit(idx)
