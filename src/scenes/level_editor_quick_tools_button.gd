extends Button

@onready var point_icon: CompressedTexture2D = preload("res://assets/ui/tool_pointer.png")
@onready var modify_icon: CompressedTexture2D = preload("res://assets/ui/tool_modify.png")
@onready var hold_icon: CompressedTexture2D = preload("res://assets/ui/tool_hold.png")
@onready var voice_icon: CompressedTexture2D = preload("res://assets/ui/level_editor_icon_audio.png")

@onready var note_selector = $"../../NoteSelector"

func _ready():
	set_tool()

func set_tool(change: int = 0):
	LevelEditor.current_tool = wrapi(LevelEditor.current_tool+change,0,LevelEditor.TOOL.keys().size())
	if change != 0: note_selector.deselect_notes()
	
	match LevelEditor.current_tool:
		LevelEditor.TOOL.POINT:
			icon = point_icon
		LevelEditor.TOOL.MODIFY:
			icon = modify_icon
		LevelEditor.TOOL.HOLD:
			icon = hold_icon
		LevelEditor.TOOL.VOICE:
			icon = voice_icon

func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_released():
		if event.button_index == MOUSE_BUTTON_LEFT:
			set_tool(1)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			set_tool(-1)
