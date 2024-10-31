class_name Assets

static var lib: Dictionary

static var act_thumb: ImageTexture
static var level_thumb: ImageTexture
static var level_splash: ImageTexture

static func load_asset(file: String):
	Console.log({"message": "Loading Asset: %s" % file, "verbose": true})
	match file.get_extension().to_lower():
		"mp3":
			lib[file.get_file().to_lower()] = Files.load_mp3(file)
		"ogg":
			lib[file.get_file().to_lower()] = AudioStreamOggVorbis.load_from_file(file)
		"png","jpg","jpeg","webp":
			lib[file.get_file().to_lower()] = Files.load_image(file)
		"ogv":
			var stream: VideoStreamTheora = VideoStreamTheora.new()
			stream.set_file(file)
			lib[file.get_file().to_lower()] = stream
		"webm","mp4","mov":
			if ClassDB.class_exists("VideoStreamFFmpeg"):
				var stream = ClassDB.instantiate("VideoStreamFFmpeg")
				stream.set_file(file)
				lib[file.get_file().to_lower()] = stream
		_:
			Console.log({"message": "Unknown Asset: %s" % file, "verbose": true, "type": 1})

static func get_asset(asset: String) -> Variant:
	if asset.is_empty(): return
	if lib.has(asset.to_lower()): return lib[asset.to_lower()]
	
	Console.log({"message": "Could not load asset %s" % asset, "type": 1})
	return null
