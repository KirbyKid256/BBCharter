extends OptionButton

@onready var notes: Node2D = $"../../NoteTimeline/TimelineRoot/Notes"

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)

func _on_editor_level_loaded():
	disabled = false
	MenuCache.level_difficulty_index = 0
	reload_items()

func reload_items():
	clear()
	
	for i in Config.notes['charts'].size():
		add_item(Config.notes['charts'][i]['name'], i)
	
	select(MenuCache.level_difficulty_index)
	_on_item_selected(selected)

func _on_item_selected(index):
	Util.clear_children_node_2d(notes)
	MenuCache.level_difficulty_index = index
	notes.load_notes()
