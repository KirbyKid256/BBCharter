class_name Files

static func get_log_path() -> String:
	return ProjectSettings.globalize_path("user://logs/bbcharter.log")

static func load_mp3(path: String) -> AudioStreamMP3:
	var file: FileAccess = FileAccess.open(path, FileAccess.ModeFlags.READ)
	var stream: AudioStreamMP3 = AudioStreamMP3.new()
	if file != null: stream.data = file.get_buffer(file.get_length())
	return stream

static func load_image(path: String, exts: PackedStringArray = []) -> ImageTexture:
	if path.get_extension().length() > 0 and FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		if image == null: return
		image.premultiply_alpha()
		return ImageTexture.create_from_image(image)
	else:
		if exts.is_empty(): exts = ['.png','.jpg','.jpeg','.webp']
		for ext in exts: if FileAccess.file_exists(path + ext):
			var image: Image = Image.load_from_file(path + ext)
			if image == null: continue
			image.premultiply_alpha()
			return ImageTexture.create_from_image(image)
	
	Console.log({"message": "Image not found: [color=red]%s[/color]" % path.trim_prefix(ProjectSettings.globalize_path("res://")), "type": 1})
	return null
