extends MenuBar

enum FILE {NEW,OPEN,SAVE}
@onready var file_popup_menu: PopupMenu = $File

enum EDIT {UNDO,REDO,CUT,COPY,PASTE}
@onready var edit_popup_menu: PopupMenu = $Edit
@onready var notes: Node2D = $"../NoteTimeline/TimelineRoot/Notes"

enum ADD {SHUTTER,MODIFIER}
@onready var add_popup_menu: PopupMenu = $Add
@onready var backgrounds: Node2D = $'../ScrollContainer/Keyframes/Backgrounds/Track'
@onready var loopsounds: Node2D = $'../ScrollContainer/Keyframes/LoopSounds/Track'
@onready var voices: Node2D = $'../ScrollContainer/Keyframes/VoiceBanks/Track'
@onready var shutters: Node2D = $'../ScrollContainer/Keyframes/Shutters/Track'
@onready var modifiers: Node2D = $'../ScrollContainer/Keyframes/Modifiers/Track'

enum HELP {CONTROLS,WIKI,DISCORD}

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	Global.undo_redo.version_changed.connect(_on_undo_or_redo)
	
	for i in edit_popup_menu.item_count:
		edit_popup_menu.set_item_disabled(i, true)
	set_menu_disabled(1, true)
	
	for i in add_popup_menu.item_count:
		add_popup_menu.set_item_disabled(i, true)
	set_menu_disabled(2, true)
	
	if OS.get_name() == "macOS":
		set_menu_hidden(3, true)
	
	if is_native_menu(): position.y -= size.y
	if Editor.project_loaded: _on_editor_project_loaded()

func _on_editor_project_loaded():
	#File
	file_popup_menu.set_item_disabled(2, false)
	#Edit
	set_menu_disabled(1, false)
	for i in edit_popup_menu.item_count:
		edit_popup_menu.set_item_disabled(i, false)
	_on_undo_or_redo()
	#Add
	set_menu_disabled(2, false)
	for i in add_popup_menu.item_count:
		add_popup_menu.set_item_disabled(i, false)

func _on_undo_or_redo():
	edit_popup_menu.set_item_disabled(0, not Global.undo_redo.has_undo())
	edit_popup_menu.set_item_disabled(1, not Global.undo_redo.has_redo())

func _input(event: InputEvent):
	if not Editor.project_loaded: return
	if not Editor.controls_enabled: return
	
	if event.is_action_pressed("ui_editor_add_item"):
		add_popup_menu.position = get_global_mouse_position()
		add_popup_menu.popup()

func _on_file_id_pressed(id):
	match id:
		FILE.NEW: Global.file_dialog.new_project()
		FILE.OPEN: Global.file_dialog.open_project()
		FILE.SAVE:
			LevelEditor.save_level() 
			Global.save_indicator.show_saved_succes()

func _on_edit_id_pressed(id):
	match id:
		EDIT.UNDO: Global.undo_redo.undo()
		EDIT.REDO: Global.undo_redo.redo()
		EDIT.CUT: notes.cut_selected_notes()
		EDIT.COPY: notes.copy_selected_notes()
		EDIT.PASTE: notes.paste_selected_notes()

func _on_add_id_pressed(id):
	match id:
		ADD.SHUTTER: shutters.create_keyframe()
		ADD.MODIFIER: modifiers.create_keyframe()
		2: backgrounds.create_keyframe({'sprite_sheet': ""})
		3: loopsounds.create_keyframe({'audio_path': ""})
		4: voices.create_keyframe({'audio_path': []})

func _on_help_id_pressed(id):
	match id:
		HELP.CONTROLS: OS.shell_open("https://github.com/KirbyKid256/BBCharter?tab=readme-ov-file#bb-charter")
		HELP.WIKI: OS.shell_open("https://github.com/KirbyKid256/BBCharter/wiki")
		HELP.DISCORD: OS.shell_open("https://discord.gg/beatbanger")
