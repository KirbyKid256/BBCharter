extends Control

@onready var volume: HSlider = $Volume
@onready var screen: OptionButton = $Screen
@onready var resolution: OptionButton = $Resolution

func _ready():
	if SettingsManager.data.is_empty():
		SettingsManager.load()
		SettingsManager.set_display_mode()
		SettingsManager.set_resolution()
	
	for res in SettingsManager.get_available_resolutions():
		var label: String = str(res).replace("(", "").replace(")", "")
		resolution.add_item(label)
	
	volume.value = SettingsManager.data.volume
	screen.selected = SettingsManager.data.screen
	resolution.selected = SettingsManager.data.resolution
	
	_on_volume_value_changed(volume.value)

func _on_volume_value_changed(value):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_volume_drag_ended(value_changed):
	if value_changed:
		SettingsManager.data.volume = volume.value
		SettingsManager.save()

func _on_screen_item_selected(index):
	SettingsManager.data.screen = index
	SettingsManager.set_display_mode()
	SettingsManager.save()

func _on_resolution_item_selected(index):
	SettingsManager.data.resolution = index
	SettingsManager.set_resolution()
	SettingsManager.save()
