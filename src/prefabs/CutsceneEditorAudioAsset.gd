extends Control

@onready var bus_selection = $BusSelection
@onready var label = $Panel/Label
@onready var rename_audio = $RenameAudio

var index: int
var bus_array: Array = [
	"Master",
	"Music",
	"SFX",
	"Voice"
]

func _ready():
	if not CutsceneEditor.get_current_panel().has('audio'): return
	update_format()
	update_visuals()

func update_visuals():
	var audio_bank: Dictionary = CutsceneEditor.get_current_panel().get("audio", [])[index]
	label.text = audio_bank.get("path", "")
	bus_selection.selected = bus_array.find(audio_bank.get("bus", "Voice"))

func _on_bus_selection_item_selected(bus_idx: int):
	CutsceneEditor.get_current_panel().audio[index]["bus"] = bus_selection.get_item_text(bus_idx)

func update_format():
	if CutsceneEditor.get_current_panel().get("audio", [])[index] is String:
		CutsceneEditor.get_current_panel().get("audio", [])[index] = {"path": CutsceneEditor.get_current_panel().get("audio", [])[index]}
	update_visuals()

func _on_label_gui_input(event):
	if EventManager.left_mouse_clicked(event):
		rename_audio.text = label.text
		rename_audio.show()
		rename_audio.grab_focus()

func _on_panel_gui_input(event):
	if not rename_audio.visible and EventManager.right_mouse_clicked(event):
		CutsceneEditor.get_current_panel().get("audio", []).remove_at(index)
		Util.free_node(self)

func _on_rename_audio_text_submitted(new_text):
	label.text = new_text
	rename_audio.clear()
	rename_audio.hide()
	CutsceneEditor.get_current_panel().get("audio", [])[index].path = new_text

func _on_rename_audio_focus_exited():
	rename_audio.clear()
	rename_audio.hide()
