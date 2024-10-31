extends Control
class_name ImageTrimmer

const image_trim_frame_prefab: Resource = preload("res://src/scenes/LevelEditor/image_trim_frame.tscn")

@onready var preview_animation: AnimatedSprite2D = $PreviewAnimation
@onready var file_drop: LevelEditorFileDrop = $"../FileDrop"
@onready var frame_slider: ImageTrimmerFrameSlider = $FrameSlider

var cache_directory: String
var file_list: Array

func _input(event: InputEvent):
	if not visible: return
	if event.is_action_pressed("ui_accept"):
		if preview_animation.is_playing():
			preview_animation.pause()
		else:
			preview_animation.play()

func split_to_frames(input_file: String):
	cache_directory = Editor.project_path.path_join("_cache")
	DirAccess.make_dir_absolute(cache_directory)
	
	var output_file = cache_directory.path_join("%d.png")
	await FFmpeg.ff_execute(["-i", input_file, "-vf", "scale=-1:720", output_file, "-y"])
	
	populate_trim_container()
	preview_animation.play()

func populate_trim_container():
	preview_animation.sprite_frames.clear(&"default")
	
	file_list = DirAccess.get_files_at(cache_directory)
	file_list.sort_custom(sort_files_numerically)
	
	for file: String in file_list:
		var full_path = cache_directory.path_join(file)
		var image_texture = Files.load_image(full_path)
		preview_animation.sprite_frames.add_frame(&"default", image_texture)
	
	show()
	frame_slider.setup_slider()

func sort_files_numerically(a: String, b: String):
	return int(a.get_basename()) < int(b.get_basename())

func set_start_frame(frame_num: int):
	Console.log({"message": "Setting start frame to frame %s" % frame_num})
	
	var preceding_files = file_list.filter(func(file: String): return int(file.get_basename()) < frame_num)
	
	for file: String in preceding_files:
		var new_value = int(file.get_basename()) + file_list.size()
		var new_filename = "%s.png" % new_value
		DirAccess.rename_absolute(cache_directory.path_join(file), cache_directory.path_join(new_filename))
		await get_tree().process_frame
	
	populate_trim_container()

func mass_delete(frame_num: int, before: bool):
	Console.log({"message": "Trimming frames from %s" % frame_num})
	
	var files_to_delete = []
	if before: files_to_delete = file_list.filter(func(file: String): return int(file.get_basename()) < frame_num)
	else: files_to_delete = file_list.filter(func(file: String): return int(file.get_basename()) > frame_num)
	
	for file: String in files_to_delete:
		DirAccess.remove_absolute(cache_directory.path_join(file))
		await get_tree().process_frame
	
	populate_trim_container()

func import_to_project():
	Console.log({"message": "Importing Sheet"})
	create_sprite_sheet_from_seq()

func create_sprite_sheet_from_seq():
	for i in file_list.size():
		var file = cache_directory.path_join(file_list[i])
		DirAccess.rename_absolute(file, cache_directory.path_join("%s.png" % i))
	
	var total_frames = file_list.size()
	var h_frames = FFmpeg.calculate_sheet_dimensions(total_frames)["h"]
	var v_frames = FFmpeg.calculate_sheet_dimensions(total_frames)["v"]
	
	var input_file = cache_directory.path_join("%d.png")
	var time_file_name = roundi(Time.get_unix_time_from_system() * 1000)
	var output_file = Editor.project_path.path_join("images/%s.png" % time_file_name)
	
	await FFmpeg.ff_execute(["-i", input_file, "-vf", "scale=-1:720:sws_flags=lanczos,tile=%sx%s" % [h_frames, v_frames], "-pred", "mixed", output_file, "-y"])
	file_drop.add_new_animation_asset({
		"sprite_sheet": output_file,
		"sheet_data": {
			"h": h_frames,
			"total": total_frames,
			"v": v_frames
		}}, LevelEditor.IMAGE.ANIMATION)
	
	await get_tree().process_frame
	delete_trim_cache()

func _on_cancel_button_button_up():
	delete_trim_cache()

func delete_trim_cache():
	for file in DirAccess.get_files_at(cache_directory): DirAccess.remove_absolute(cache_directory.path_join(file))
	DirAccess.remove_absolute(cache_directory)
	hide()

func rename_in_order():
	for i in file_list.size():
		var file = cache_directory.path_join(file_list[i])
		DirAccess.rename_absolute(file, cache_directory.path_join("%s.png" % i))

func _on_set_start_button_up(): set_start_frame(preview_animation.frame)
func _on_trim_before_button_up(): mass_delete(preview_animation.frame, true)
func _on_trim_after_button_up(): mass_delete(preview_animation.frame, false)
