extends MenuBar

enum FILE {NEW,OPEN,SAVE}
@onready var file_popup_menu: PopupMenu = $File
@onready var file_dialog: FileDialog = $"../FileDialog"
@onready var save_indicator: SaveIndicator = $"../SaveIndicator"

enum EDIT {UNDO,REDO,CUT,COPY,PASTE}
@onready var notes: Node2D = $"../NoteTimeline/TimelineRoot/Notes"

enum ADD {SHUTTER,MODIFIER}
@onready var add_popup_menu: PopupMenu = $Add
@onready var loopsounds: Node2D = $'../ScrollContainer/KeyframeAssetGrid/SoundLoops/Track'
@onready var voices: Node2D = $'../ScrollContainer/KeyframeAssetGrid/VoiceBanks/Track'
@onready var shutters: Node2D = $'../ScrollContainer/KeyframeAssetGrid/Shutters/Track'
@onready var modifiers: Node2D = $'../ScrollContainer/KeyframeAssetGrid/Modifiers/Track'

enum DIFFICULTY {ADD,RENAME,DELETE,REARRANGE}

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)
	
	set_menu_disabled(1, true)
	set_menu_disabled(2, true)
	
	if is_native_menu(): position.y -= size.y

func _on_editor_level_loaded():
	#File
	file_popup_menu.set_item_disabled(2, false)
	#Edit
	set_menu_disabled(1, false)
	#Add
	set_menu_disabled(2, false)

func _input(event: InputEvent):
	if not Editor.level_loaded: return
	if not LevelEditor.controls_enabled: return
	
	if event.is_action_pressed("ui_editor_add_item"):
		add_popup_menu.position = get_global_mouse_position()
		add_popup_menu.popup()

func _on_file_id_pressed(id):
	match id:
		FILE.NEW: file_dialog.new_project()
		FILE.OPEN: file_dialog.open_project()
		FILE.SAVE:
			LevelEditor.save_project() 
			save_indicator.show_saved_succes()

func _on_edit_id_pressed(id):
	match id:
		EDIT.COPY: notes.copy_selected_notes()
		EDIT.PASTE: notes.paste_selected_notes()

func _on_add_id_pressed(id):
	match id:
		ADD.SHUTTER: shutters.create_shutter()
		ADD.MODIFIER: modifiers.create_modifier()
		2: loopsounds.create_loopsound_audio({'audio_path': ""})
		3: voices.create_voice_audio({'audio_path': []})
