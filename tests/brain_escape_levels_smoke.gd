extends SceneTree

const Levels = preload("res://scripts/brain_escape_levels.gd")

func _initialize() -> void:
	var seen_kinds: Dictionary = {}
	var seen_tiers: Dictionary = {}
	for level_number in range(1, Levels.COUNT + 1):
		var data: Dictionary = Levels.get_level(level_number)
		assert(int(data.number) == level_number, "Level numbering is not continuous")
		assert(not str(data.prompt).is_empty(), "Level %d has no prompt" % level_number)
		assert(not str(data.hint).is_empty(), "Level %d has no hint" % level_number)
		assert(Levels.answer_is_correct(data, data.answer), "Level %d rejects its authored answer" % level_number)
		seen_kinds[str(data.kind)] = true
		seen_tiers[int(data.tier)] = true
	assert(seen_kinds.size() == 10, "Puzzle catalog must cover all ten mechanics")
	assert(seen_tiers.size() == 5, "Puzzle catalog must cover all five difficulty bands")
	print("PASS: 50 levels, 10 puzzle mechanics, 5 difficulty bands, authored answers validate.")
	quit(0)
