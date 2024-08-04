extends BaseMenu
class_name Menu

var vertical: bool ## If true the menu with be verical in stead of horizontal
var affect_fade: bool ## If true the item's z_indexes will cascade
var speed: float = 1.0
var speed_override: float = 1.0

var actions: PackedStringArray = ["ui_left", "ui_right"]

func _ready():
	set_name("MenuManager") 
	if vertical: actions = ["ui_up", "ui_down"]
	refresh()

## Replaces items list with new one
func register_items(item_array: Array[Node]):
	items = item_array
	speed = 0
	refresh()

func _input(event):
	if not Editor.controls_enabled: return
	if not get_parent().is_visible_in_tree(): return
	if items.is_empty(): return
	
	if event.is_action(actions[0]) and event.is_pressed(): cycle_menu(-1)
	elif event.is_action(actions[1]) and event.is_pressed(): cycle_menu(1)

func cycle_menu(direction: int):
	speed = speed_override
	if items.size() <= 1: return
	index = wrapi(index + direction, 0, items.size())
	refresh()

## Runs the tween that moves the menu items
func refresh():
	if items.is_empty(): return
	if items.size() <= index: index = 0 # If index is too high go back to 0
	
	selected_item = items[index]
	
	if highlight:
		for i: int in items.size():
			items[i].highlight(i, index, false)
		selected_item.highlight(index, index, true)
	
	if use_drivers:
		for i: int in items.size():
			var tween = create_tween()
			tween.tween_property(items[i],"position", offset_position(i, index), speed).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(items[i],"scale", offset_scale(i, index), speed).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			
			if affect_z:
				items[i].z_index = offset_z_index(i, index)
			if affect_fade:
				var f_tween = create_tween()
				f_tween.tween_property(items[i],"modulate", offset_fade(i, index), speed).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
				
	menu_updated.emit(selected_item)
	speed = 1.0

## Returns the positional values for each of the menu items
func offset_position(idx: int, selected_index: int):
	var button_space = idx * margin
	var button_selected_pos = selected_index * margin
	if vertical:
		return Vector2(0, button_space - button_selected_pos) 
	else:
		return Vector2(button_space - button_selected_pos,0 )

## Returns the z_index values for each of the menu items
func offset_z_index(idx: int, selected_index: int) -> int: 
	var distance = abs(idx - selected_index)
	var button_z_index = (1 - distance) 
	return button_z_index

## Returns the z_index values for each of the menu items
func offset_fade(idx: int, selected_index: int) -> Color: 
	var color_array = [Color(0.5,0.5,0.5,1.0), Color(1,1,1,1.0)]
	var distance = abs(idx - selected_index)
	var value = (1 - distance)
	
	if value < 0: return Color(1.0,1.0,1.0,0.0)
	return color_array[value]
