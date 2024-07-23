extends ScrollContainer

@export var filter = ["png", "jpg", "jpeg", "ogg", "mp3"]

@onready var asset_grid: VBoxContainer = $AssetGrid
@onready var file_button: Button = Button.new()

signal button_up(file: String)

func _ready():
	file_button.icon = preload("res://assets/ui/plus_add.png")
	file_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	file_button.custom_minimum_size.y = 40
	file_button.focus_mode = FOCUS_NONE
	file_button.add_theme_font_size_override("font_size", 20)

func reload_list():
	Util.clear_children(asset_grid)
	
	if filter.has("png") or filter.has("jpg") or filter.has("jpeg"):
		for item in DirAccess.get_files_at(Editor.level_path + "images"):
			if Assets.lib.has(item.to_lower()) and filter.has(item.get_extension()):
				var button: Button = file_button.duplicate()
				asset_grid.add_child(button)
				button.text = item
				button.button_up.connect(func(): button_up.emit(button.text))
	if filter.has("ogg") or filter.has("mp3"):
		for item in DirAccess.get_files_at(Editor.level_path + "audio"):
			if Assets.lib.has(item.to_lower()) and filter.has(item.get_extension()):
				var button: Button = file_button.duplicate()
				asset_grid.add_child(button)
				button.button_up.connect(func(): button_up.emit(button.text))
				button.text = item
