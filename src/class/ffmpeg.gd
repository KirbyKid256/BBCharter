class_name FFmpeg

static var executable_path: String

static var ffmpeg_exec_paths: Dictionary = {
	"Windows": Global.get_executable_path().path_join("bin/win64/ffmpeg.exe"),
	"macOS": Global.get_executable_path().path_join("bin/macos/ffmpeg"),
	"Linux": Global.get_executable_path().path_join("bin/linux/ffmpeg"),
}

static var ffprobe_exec_paths: Dictionary = {
	"Windows": Global.get_executable_path().path_join("bin/win64/ffprobe.exe"),
	"macOS": Global.get_executable_path().path_join("bin/macos/ffprobe"),
	"Linux": Global.get_executable_path().path_join("bin/linux/ffprobe"),
}

static func convert_file(input_file: String, output_file: String, type: String) -> String:
	# Check If File Exists
	if FileAccess.file_exists(output_file):
		Console.log({"message": "FFMPEG - File already exists: " + output_file})
		return output_file.get_file()
	
	#Get FFmpeg Executable
	executable_path = ffmpeg_exec_paths.get(OS.get_name(), "Unknown")
	if executable_path == "Unknown": Console.log({"message": "Unknown OS name: %s" % OS.get_name(), "type": 2}); return ""
	Console.log({"message": "FFmpeg found at %s..." % executable_path})
	
	# Convert Video
	Console.log({"message": "Converting Climax Video..."})
	var execute_output: Array = []
	if OS.execute(executable_path, get_command(input_file, output_file), execute_output, true) != 0:
		Console.log({"message": "Could not convert final video %s with %s" % [output_file, execute_output], "type": 2})
		return ""
	
	Console.log({"message": "Converted final video: %s" % output_file})
	return output_file.get_file() 

static func get_command(input_file: String, output_file: String) -> PackedStringArray:
	match output_file.get_extension():
		"ogv": 
			return["-y", "-i", input_file, "-c:v", "libtheora", "-q:v", "5", "-c:a", "libvorbis", "-q:a", "1",  output_file]
		"ogg": 
			return["-y", "-i", input_file, "-c:a", "libvorbis", "-q:a", "4", output_file]
		_: 
			return []

static func create_sprite_sheet_from_gif(input_file: String) -> Dictionary:
	Console.log({"message": "Converting %s to Sprite Sheet..." % input_file.get_file()})
	var total_frames = get_gif_framecount(input_file)
	var h_frames = calculate_sheet_dimensions(total_frames).h
	var v_frames = calculate_sheet_dimensions(total_frames).v
	
	var output_dir = Editor.project_path.path_join("images")
	var output_file_format: String = "sheet_%s" % input_file.get_file().replace(input_file.get_file().get_extension(), "png")
	var output_file: String = output_dir.path_join(output_file_format)
	
	# Run command
	executable_path = ffmpeg_exec_paths.get(OS.get_name(), "Unknown")
	
	var execute_output: Array = []
	execute_output = []
	OS.execute(executable_path, ffmpeg_make_sheet("%s" % input_file, h_frames, v_frames, output_file), execute_output, true)
	# FFMPEG output
	Console.log({"message": execute_output})
	
	return {"output": output_file, "h": h_frames, "v": v_frames, "total": total_frames}

static func calculate_sheet_dimensions(total_frames: float):
	var h_frames = ceil(sqrt(total_frames))
	var v_frames = round(sqrt(total_frames)) # Nearest square number
	return {"h": h_frames, "v": v_frames}

static func ffprobe_frame_count_meta(input_file: String): # Deprecated: Only works for GIFs and some MP4s since it fetches info from meta
	return ["-v", "error", "-select_streams", "v:0", "-show_entries", "stream=nb_frames", "-of", "default=noprint_wrappers=1:nokey=1", input_file]

static func ffprobe_frame_count(input_file: String): # Technically less accurate but faster than '-count_frames' + 'nb_read_frames' and more versatile
	return ["-v", "error", "-select_streams", "v:0", "-count_packets", "-show_entries", "stream=nb_read_packets", "-of", "csv=p=0", input_file]

static func ffmpeg_make_sheet(input_file: String, h_frames: int, v_frames: int, output_file: String):
	return ["-y", "-i", input_file, "-vf", "scale=-1:720:sws_flags=lanczos,tile=%sx%s" % [h_frames, v_frames], "-pred", "mixed", output_file]

static func ffmpeg_resize_720(input_file: String):
	var resized_file = "%s_resized.gif" % input_file.get_basename()
	return ["-y", "-i", input_file, "-vf", "scale=-1:720", resized_file]

static func get_gif_framecount(input_file: String) -> int:
	executable_path = ffprobe_exec_paths.get(OS.get_name(), "Unknown")
	var execute_output: Array = []
	if OS.execute(executable_path, ffprobe_frame_count(input_file), execute_output, true) != 0: pass
	return execute_output[0].replace("\r\n", "").to_int()
