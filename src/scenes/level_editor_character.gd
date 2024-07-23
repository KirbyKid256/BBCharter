extends Sprite2D

@onready var tsevent = TSEvent.new()

var data: Dictionary
var tween: Tween

func _ready():
	EventManager.editor_level_loaded.connect(_on_editor_level_loaded)
	EventManager.editor_note_hit.connect(_on_editor_note_hit)
	
	tsevent.callback = change_animation
	tsevent.config_key = "loops"
	add_child(tsevent)

func _on_editor_level_loaded():
	change_animation(0)

func change_animation(idx: int):
	if Config.keyframes['loops'].is_empty(): set_texture(null); return # Ignore if no loops
	data = Config.keyframes['loops'][idx]
	
	set_scale(Vector2(data.get('scale_multiplier', 1), data.get('scale_multiplier', 1)))
	set_hframes(data['sheet_data'].h)
	set_vframes(data['sheet_data'].v)
	set_texture(Assets.get_asset(data['animations'].normal))

func _on_editor_note_hit(note_data):
	if not Editor.level_loaded: return
	if Config.keyframes['loops'].is_empty(): return # Ignore if no loops
	if note_data['note_modifier'] == LevelEditor.NOTETYPE.GHOST: return # Ignore ghost notes
	
	var hit_note_index = Difficulty.get_chart_notes().find(note_data)
	var next_note_timestamp: float
	var current_note_timestamp: float
	var animation_duration: float
	
	if hit_note_index < Difficulty.get_chart_notes().size()-1:
		current_note_timestamp = Difficulty.get_chart_notes()[hit_note_index]['timestamp']
		# DOODLE CODED THIS It ignores consecutive ghost notes 💖
		for n in range(1, Difficulty.get_chart_notes().size() - hit_note_index):
			if Difficulty.get_chart_notes()[hit_note_index + n]['note_modifier'] != LevelEditor.NOTETYPE.GHOST:
				next_note_timestamp = Difficulty.get_chart_notes()[hit_note_index + n]['timestamp']
				break
		animation_duration = next_note_timestamp - current_note_timestamp
	
	# Ignore the animation playback if animation shares the same timestamp as the current note
	if not tsevent.index > Config.keyframes.get(tsevent.config_key).size() - 1:
		if Config.keyframes['loops'][tsevent.index]['timestamp'] == note_data['timestamp']: 
			Console.log({"message": "Note conflict! Giving priority to the transition" })
			return
	
	# Run Loop
	if tween: tween.kill() # Abort the previous animation.
	tween = get_tree().create_tween()
	set_frame(0)
	tween.tween_property(self, 'frame', data['sheet_data'].total-1, animation_duration - (animation_duration / data['sheet_data'].total))
