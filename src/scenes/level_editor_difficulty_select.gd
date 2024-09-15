extends OptionButton

@onready var notes: Node2D = $"../../NoteTimeline/TimelineRoot/Notes"

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	
	if Editor.project_loaded:
		reload_items()
		disabled = false

func _on_editor_project_loaded():
	disabled = true
	LevelEditor.difficulty_index = 0
	reload_items()
	disabled = false

func reload_items():
	clear()
	for i in Config.notes['charts'].size():
		add_item(Config.notes['charts'][i]['name'], i)
	
	select(LevelEditor.difficulty_index)
	_on_item_selected(selected)

func _on_item_selected(index):
	var old_index: int = LevelEditor.difficulty_index
	if disabled:
		Util.clear_children_node_2d(notes)
		notes.load_notes()
		return
	
	Global.undo_redo.create_action("Change Difficulty")
	Global.undo_redo.add_do_method(func():
		Util.clear_children_node_2d(notes)
		LevelEditor.difficulty_index = index
		select(index); notes.load_notes())
	Global.undo_redo.add_undo_method(func():
		Util.clear_children_node_2d(notes)
		LevelEditor.difficulty_index = old_index
		select(old_index); notes.load_notes())
	Global.undo_redo.commit_action()
