class_name MenuCache

# Editors
static var level_difficulty_index: int = 0
static var cutscene_panel_index: int = 0

static func menu_disabled(node: Node) -> bool:
	return not node.visible
