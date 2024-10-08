extends Control

@onready var file_drop: Control = $"../../../../../FileDrop"

@onready var file_name: Label = $FileName
@onready var up_button: TextureButton = $UpButton
@onready var down_button: TextureButton = $DownButton
@onready var play_button: TextureButton = $PlayButton
@onready var sound: AudioStreamPlayer = $Sound

var path: String

func setup(file_path):
	path = file_path
	file_name.text = path
	sound.stream = Assets.get_asset(path)

func _on_up_button_mouse_entered():
	up_button.modulate.a = 1.0
func _on_up_button_mouse_exited():
	up_button.modulate.a = 0.3

func _on_down_button_mouse_entered():
	down_button.modulate.a = 1.0
func _on_down_button_mouse_exited():
	down_button.modulate.a = 0.3

func _on_play_button_mouse_entered():
	play_button.modulate.a = 1.0
func _on_play_button_mouse_exited():
	play_button.modulate.a = 0.3

func _on_panel_gui_input(event):
	if EventManager.right_mouse_clicked(event):
		file_drop.pending_audio_data['audio_path'].remove_at(get_index())
		Util.free_node(self)

func _on_up_button_up():
	button_up(clampi(get_index()-1,0,file_drop.pending_audio_data['audio_path'].size()-1))

func _on_down_button_up():
	button_up(clampi(get_index()+1,0,file_drop.pending_audio_data['audio_path'].size()-1))

func button_up(idx: int):
	file_drop.pending_audio_data['audio_path'].remove_at(get_index())
	file_drop.pending_audio_data['audio_path'].insert(idx, path)
	
	file_drop.create_audio_voice_paths.move_child(self, idx)

func _on_play_button_up():
	if sound.stream: sound.play()

func _exit_tree():
	if sound.playing: sound.stop()
