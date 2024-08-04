class_name Difficulty

## Gets the chart for the current difficulty
static func get_current_chart() -> Dictionary:
	if not Config.notes.has('charts'): return {}
	return Config.notes['charts'][LevelEditor.difficulty_index]

## Gets the chart for the current difficulty
static func get_current_chart_value(key: String, fallback: Variant = null) -> Variant:
	return get_current_chart().get(key, fallback)

## Gets the chart for the current difficulty
static func get_chart_notes() -> Array:
	return get_current_chart()['notes']
