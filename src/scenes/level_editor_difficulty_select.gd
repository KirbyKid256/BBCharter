extends OptionButton

@onready var notes: Node2D = $"../../NoteTimeline/TimelineRoot/Notes"

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	
	if Editor.project_loaded:
		disabled = false; clear()
		for i in Config.notes['charts'].size():
			add_item(Config.notes['charts'][i]['name'], i)
		select(LevelEditor.difficulty_index)

func _on_editor_project_loaded():
	disabled = false
	LevelEditor.difficulty_index = 0
	reload_items()

func reload_items():
	clear()
	for i in Config.notes['charts'].size():
		add_item(Config.notes['charts'][i]['name'], i)
	
	select(LevelEditor.difficulty_index)
	_on_item_selected(selected)

func _on_item_selected(index):
	Util.clear_children_node_2d(notes)
	LevelEditor.difficulty_index = index
	notes.load_notes()
