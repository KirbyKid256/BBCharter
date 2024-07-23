extends OptionButton

@onready var notes: Node2D = $"../../NoteTimeline/TimelineRoot/Notes"

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)

func _on_editor_level_loaded():
	clear()
	
	for i in Config.notes['charts'].size():
		add_item(Config.notes['charts'][i]['name'], i)
	
	disabled = false
	_on_item_selected(0)

func _on_item_selected(index):
	Util.clear_children_node_2d(notes)
	MenuCache.level_difficulty_index = index
	notes.load_notes()
