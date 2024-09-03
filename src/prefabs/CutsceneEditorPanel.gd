extends Node2D

@onready var cutscene_editor = $"../../"
@onready var cutscene_editor_panels = $"../"

@onready var image_preview = $ImagePreview
@onready var dialogue = $Dialogue
@onready var character_name = $CharacterName

@onready var left_button = $LeftButton
@onready var right_button = $RightButton

func update_visual():
	var data = CutsceneEditor.data[Cutscene.type].lines[get_index()]
	character_name.text = data.get("character", "")
	dialogue.text = data.get("dialogue", "")
	if data.has("src"): image_preview.texture = Cutscene.get_image(data["src"])
	
	if CutsceneEditor.data[Cutscene.type].characters.has(character_name.text):
		var color = CutsceneEditor.data[Cutscene.type].characters[character_name.text].get("color", [1,1,1])
		color = Color(color[0], color[1], color[2])
		character_name.modulate = color

func highlight(_idx: int, _selected_idx: int, state: bool):
	modulate.a = 1.0 if state else 0.6

func _on_left_button_mouse_entered():
	left_button.modulate.a = 1.0

func _on_left_button_mouse_exited():
	left_button.modulate.a = 0.3

func _on_right_button_mouse_entered():
	right_button.modulate.a = 1.0

func _on_right_button_mouse_exited():
	right_button.modulate.a = 0.3

func _on_left_button_up():
	button_up(clampi(get_index()-1,0,CutsceneEditor.data[Cutscene.type].lines.size()-1))

func _on_right_button_up():
	button_up(clampi(get_index()+1,0,CutsceneEditor.data[Cutscene.type].lines.size()-1))

func button_up(idx: int):
	if idx == get_index(): return
	var data = CutsceneEditor.data[Cutscene.type].lines[get_index()]
	
	CutsceneEditor.data[Cutscene.type].lines.remove_at(get_index())
	CutsceneEditor.data[Cutscene.type].lines.insert(idx, data)
	
	cutscene_editor.menu_manager.refresh()
	cutscene_editor_panels.get_child(idx).update_visual()
	update_visual()
