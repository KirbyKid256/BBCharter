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
	
	_on_item_selected(LevelEditor.difficulty_index)

func _on_item_selected(index):
	var old_index: int = LevelEditor.difficulty_index
	var change_diff: Callable = func(idx: int):
		Util.clear_children_node_2d(notes)
		LevelEditor.difficulty_index = idx
		select(idx); notes.load_notes()
	
	if disabled or Global.undo_redo.get_current_action_name().is_empty():
		change_diff.call(index)
		return
	
	Global.undo_redo.create_action("Change Difficulty")
	Global.undo_redo.add_do_method(func(): change_diff.call(index))
	Global.undo_redo.add_undo_method(func(): change_diff.call(old_index))
	Global.undo_redo.commit_action()
