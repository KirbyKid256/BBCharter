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

enum CLEAR {ALL,OOB,NOTE,KEYS}
@onready var clear_popup_menu: PopupMenu = $Clear
@onready var keyframes: VBoxContainer = $"../ScrollContainer/Keyframes"

enum HELP {GITHUB,DISCORD}
@onready var help_popup_menu: PopupMenu = $Help

func _ready():
	EventManager.editor_project_loaded.connect(_on_editor_project_loaded)
	Global.undo_redo.version_changed.connect(_on_undo_or_redo)
	
	#File
	for key in FILE.keys():
		var shortcut: Shortcut = Shortcut.new()
		shortcut.events = InputMap.action_get_events("ui_" + key.to_lower())
		file_popup_menu.set_item_shortcut(FILE[key], shortcut)
	
	#Edit
	for i in edit_popup_menu.item_count:
		edit_popup_menu.set_item_disabled(i, true)
	set_menu_disabled(1, true)
	var skip: int = 0
	for key in EDIT.keys():
		if key == "CUT": skip += 1
		var shortcut: Shortcut = Shortcut.new()
		shortcut.events = InputMap.action_get_events("ui_" + key.to_lower())
		edit_popup_menu.set_item_shortcut(EDIT[key] + skip, shortcut)
	
	#Add
	for i in add_popup_menu.item_count:
		add_popup_menu.set_item_disabled(i, true)
	set_menu_disabled(2, true)
	
	#Clear
	for i in clear_popup_menu.item_count:
		clear_popup_menu.set_item_disabled(i, true)
	set_menu_disabled(3, true)
	
	#Help
	help_popup_menu.set_item_icon(HELP.GITHUB, preload("res://assets/ui/help_github_icon.png"))
	help_popup_menu.set_item_icon(HELP.DISCORD, preload("res://assets/ui/help_discord_icon.png"))
	if OS.get_name() == "macOS":
		set_menu_hidden(4, true)
	
	if is_native_menu(): position.y -= size.y
	if Editor.project_loaded: _on_editor_project_loaded()

func _on_editor_project_loaded():
	#File
	file_popup_menu.set_item_disabled(2, false)
	#Edit
	set_menu_disabled(1, false)
	_on_undo_or_redo()
	#Add
	set_menu_disabled(2, false)
	for i in add_popup_menu.item_count:
		add_popup_menu.set_item_disabled(i, false)
	#Clear
	set_menu_disabled(3, false)
	for i in clear_popup_menu.item_count:
		clear_popup_menu.set_item_disabled(i, false)

func _on_undo_or_redo():
	edit_popup_menu.set_item_disabled(EDIT.UNDO, not Global.undo_redo.has_undo())
	edit_popup_menu.set_item_disabled(EDIT.REDO, not Global.undo_redo.has_redo())

func _input(event: InputEvent):
	if not Editor.project_loaded: return
	if not Editor.controls_enabled: return
	
	if event.is_action_pressed("ui_editor_add_item"):
		add_popup_menu.position = get_global_mouse_position()
		add_popup_menu.popup()

func _on_file_id_pressed(id):
	if not Editor.controls_enabled: return
	
	match id:
		FILE.NEW: Global.file_dialog.new_project()
		FILE.OPEN: Global.file_dialog.open_project()
		FILE.SAVE:
			if not Editor.project_loaded: return
			LevelEditor.save_level() 
			Global.save_indicator.show_saved_succes()

func _on_edit_id_pressed(id):
	if not Editor.controls_enabled: return
	if not Editor.project_loaded: return
	
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
		HELP.GITHUB: OS.shell_open("https://github.com/KirbyKid256/BBCharter")
		HELP.DISCORD: OS.shell_open("https://discord.gg/beatbanger")

func _on_clear_id_pressed(id):
	var song_length_offset = snappedf(LevelEditor.song_length - Config.settings['song_offset'], 0.001)
	var clear_keys: Callable = func(idx: int = -1):
		if idx < 0:
			var tracks: Array
			for i in keyframes.get_child_count():
				tracks.append(keyframes.get_child(i).get_node("Track"))
			
			for i in keyframes.get_child_count():
				if idx < -1:
					for data in Config.keyframes[tracks[i].key].filter(func(key): return key.timestamp > song_length_offset or key.timestamp < -Config.settings['song_offset']):
						tracks[i].remove_keyframe(data)
				else:
					tracks[i].clear_keyframes()
		else:
			var track = keyframes.get_child(idx).get_node("Track")
			if track.key != "modifiers" and track.get_child_count() > 0 or track.key == "modifiers" and track.get_child_count() > 1:
				track.clear_keyframes()
	
	var note_data: Array = Difficulty.get_chart_notes().duplicate(true)
	var keys_data: Array; var empty_keys: int = 0;
	for i in keyframes.get_child_count():
		var track = keyframes.get_child(i).get_node("Track")
		keys_data.append(Config.keyframes[track.key].duplicate(true))
		if keys_data[i].is_empty() or track.key == "modifiers" and keys_data[i].size() <= 1:
			empty_keys += 1
	
	match id:
		CLEAR.ALL:
			if note_data.is_empty() and empty_keys == keys_data.size(): return
			
			Global.undo_redo.create_action("Clear All")
			Global.undo_redo.add_do_method(func():
				notes.clear_notes(); clear_keys.call())
			Global.undo_redo.add_undo_method(func():
				Difficulty.get_current_chart()['notes'] = note_data.duplicate(true)
				notes.load_notes()
				for i in keyframes.get_child_count():
					var track = keyframes.get_child(i).get_node("Track")
					Config.keyframes[track.key] = keys_data[i].duplicate(true)
					track.load_keyframes())
			Global.undo_redo.commit_action()
		CLEAR.OOB:
			empty_keys = 0
			for i in keyframes.get_child_count():
				var track = keyframes.get_child(i).get_node("Track")
				keys_data[i] = Config.keyframes[track.key].filter(func(key): return key.timestamp > song_length_offset or key.timestamp < -Config.settings['song_offset'])
				if keys_data[i].is_empty():
					empty_keys += 1
			
			if note_data.is_empty() and empty_keys == keys_data.size(): return
			
			Global.undo_redo.create_action("Clear Out of Bounds")
			Global.undo_redo.add_do_method(func():
				notes.clear_notes_oob(); clear_keys.call(-2))
			Global.undo_redo.add_undo_method(func():
				Difficulty.get_current_chart()['notes'] = note_data.duplicate(true)
				notes.load_notes()
				for i in keyframes.get_child_count():
					var track = keyframes.get_child(i).get_node("Track")
					Config.keyframes[track.key] = keys_data[i].duplicate(true)
					track.load_keyframes())
			Global.undo_redo.commit_action()
		CLEAR.NOTE:
			if note_data.is_empty(): return
			
			Global.undo_redo.create_action("Clear Notes")
			Global.undo_redo.add_do_method(notes.clear_notes)
			Global.undo_redo.add_undo_method(func():
				Difficulty.get_current_chart()['notes'] = note_data.duplicate(true)
				notes.load_notes())
			Global.undo_redo.commit_action()
		CLEAR.KEYS:
			if empty_keys == keys_data.size(): return
			
			Global.undo_redo.create_action("Clear Keyframes")
			Global.undo_redo.add_do_method(func(): clear_keys.call())
			Global.undo_redo.add_undo_method(func():
				for i in keyframes.get_child_count():
					var track = keyframes.get_child(i).get_node("Track")
					Config.keyframes[track.key] = keys_data[i].duplicate(true)
					track.load_keyframes())
			Global.undo_redo.commit_action()
		_:
			var idx: int = id - 4
			var track = keyframes.get_child(idx).get_node("Track")
			if keys_data[idx].is_empty() or track.key == "modifiers" and keys_data[idx].size() <= 1: return
			
			Global.undo_redo.create_action("Clear Keyframes")
			Global.undo_redo.add_do_method(func(): clear_keys.call(idx))
			Global.undo_redo.add_undo_method(func():
				Config.keyframes[track.key] = keys_data[idx].duplicate(true)
				track.load_keyframes())
			Global.undo_redo.commit_action()
