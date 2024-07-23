extends Node
class_name BaseMenu

# Globals
var enabled: bool = true
var is_global_menu: bool ##If true. Ingores menu disabling functions

# Menu Info
var index: int = 0 ## The index of the instanced menu
var items: Array[Node] ## An array of nodes to be used as menu items
var selected_item: Node2D
var root: Node2D ## The menu's origin point

# Menu Settings
var margin: int = 512 ## Amount in pixels to separate the menu items
var affect_z: bool ## If true the item's z_indexes will cascade
var scales: PackedFloat32Array = [1.0,1.5] ## The deselected and selected scales for the menu items
var use_drivers: bool = true ## The deselected and selected scales for the menu items
var highlight: bool ## If true, items will run a highlighted() when selected

# Input Stuff
var input_hold: bool = true ## If true the menu will scroll as long as the user holds the input
var input_hold_activation_delay: float = 0.0 ## Delay between scrolling
var input_hold_delay: float = 0.0 ## Delay between scrolling

func reset(): index = 0
func enable(): enabled = true
func disable(): enabled = false

func cycle_menu(direction: int):
	if items.size() <= 1: return
	index = wrapi(index + direction, 0, items.size())

## Returns the scale values for each of the menu items
func offset_scale(idx: int, selected_index:int) -> Vector2:
	var button_scale = scales[1] if idx == selected_index else scales[0]
	return Vector2(button_scale ,button_scale)

signal menu_updated(selected_item: Node2D)
