extends RefCounted
class_name BrainEscapeLevels

const COUNT := 50
const KINDS := ["number", "hidden", "pattern", "door", "wires", "water", "shape", "memory", "move", "missing"]
const CATEGORIES := {
	"number": "Number logic",
	"hidden": "Hidden object",
	"pattern": "Pattern match",
	"door": "Secret door",
	"wires": "Electrical wires",
	"water": "Water flow",
	"shape": "Shape match",
	"memory": "Memory test",
	"move": "Move the pieces",
	"missing": "Missing piece",
}
const SECTIONS := ["Curiosity Wing", "Logic Hall", "Number Vault", "Mirror Chamber", "Master Vault"]
const DIFFICULTIES := ["EASY", "LOGIC", "MATH", "ADVANCED", "EXPERT"]

static func get_level(level_number: int) -> Dictionary:
	var n := clampi(level_number, 1, COUNT)
	var tier := int((n - 1) / 10)
	var kind: String = KINDS[(n - 1) % 10]
	var result := {
		"number": n,
		"tier": tier,
		"kind": kind,
		"category": CATEGORIES[kind],
		"section": SECTIONS[tier],
		"difficulty": DIFFICULTIES[tier],
		"time_limit": 126 - tier * 14,
	}
	result.merge(_payload(kind, tier), true)
	return result

static func get_all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for n in range(1, COUNT + 1):
		result.append(get_level(n))
	return result

static func answer_is_correct(level_data: Dictionary, guess: Variant) -> bool:
	var answer: Variant = level_data.get("answer", null)
	if typeof(answer) == TYPE_ARRAY:
		return typeof(guess) == TYPE_ARRAY and (guess as Array) == (answer as Array)
	if typeof(answer) == TYPE_INT:
		return int(guess) == int(answer)
	return str(guess).strip_edges().to_upper() == str(answer).strip_edges().to_upper()

static func _payload(kind: String, tier: int) -> Dictionary:
	match kind:
		"number":
			var stages := [
				{"title":"Double Steps", "prompt":"Follow the rule: 2, 4, 8, 16, ?", "hint":"Each number is multiplied by two.", "options":["24", "30", "32", "36"], "answer":"32"},
				{"title":"The Twin Ladder", "prompt":"Complete the sequence: 3, 6, 12, 24, ?", "hint":"The same operation repeats at every step.", "options":["36", "42", "48", "54"], "answer":"48"},
				{"title":"Mirror Multiples", "prompt":"What comes next? 4, 9, 19, 39, ?", "hint":"Double the number, then add one.", "options":["69", "77", "79", "81"], "answer":"79"},
				{"title":"Growing Gaps", "prompt":"Find the missing number: 1, 4, 10, 22, ?", "hint":"The gaps double: +3, +6, +12, then +24.", "options":["42", "44", "46", "48"], "answer":"46"},
				{"title":"A Fibonacci Lock", "prompt":"The first numbers are 2, 3, 5, 9, 17, ?", "hint":"The gaps are 1, 2, 4, 8. Double the gap again.", "options":["25", "31", "33", "35"], "answer":"33"},
			]
			return stages[tier]
		"hidden":
			var stages := [
				{"title":"The Doubled Key", "prompt":"One object appears twice: KEY, STAR, BOOK, KEY, MAP. Which object is repeated?", "hint":"Scan the list from left to right and look for an exact repeat.", "options":["KEY", "STAR", "BOOK", "MAP"], "answer":"KEY"},
				{"title":"Odd One in the Workshop", "prompt":"Which item does not belong with the others: hinge, bolt, latch, banana, handle?", "hint":"Four items help a door open or close.", "options":["HINGE", "BOLT", "LATCH", "BANANA", "HANDLE"], "answer":"BANANA"},
				{"title":"The Hidden Word", "prompt":"Read the first letter of each word: Silent Owls Find Tiny Stars. What word is hidden?", "hint":"Take the first letter of every word in order.", "options":["SOFTS", "SOFT", "OFTS", "STARS"], "answer":"SOFTS"},
				{"title":"Reflection Room", "prompt":"Which shape has one vertical line of symmetry, one straight edge and one curved edge?", "hint":"A circle has many symmetry lines; a crescent has one curved edge.", "options":["SEMICIRCLE", "TRIANGLE", "ZIGZAG", "SPIRAL"], "answer":"SEMICIRCLE"},
				{"title":"The Expert's Shadow", "prompt":"A word is hidden across the join: 'brAIn stoRM'. Which object is concealed by the capital letters?", "hint":"Read only the capital letters in order.", "options":["ARM", "AIM", "AIR", "RIM"], "answer":"AIM"},
			]
			return stages[tier]
		"pattern":
			var stages := [
				{"title":"Alternating Lights", "prompt":"Complete the rhythm: circle, triangle, circle, triangle, ?", "hint":"The two shapes alternate.", "options":["CIRCLE", "TRIANGLE", "SQUARE", "STAR"], "answer":"CIRCLE"},
				{"title":"Color Pulse", "prompt":"The tiles repeat: teal, teal, gold, teal, teal, gold, ?", "hint":"Look for the repeating group of three.", "options":["TEAL", "GOLD", "CORAL", "NAVY"], "answer":"TEAL"},
				{"title":"Letter Orbit", "prompt":"Continue the pattern: A, C, F, J, O, ?", "hint":"The jumps grow by one letter each time: +2, +3, +4, +5.", "options":["S", "T", "U", "V"], "answer":"U"},
				{"title":"Double-Beat Pattern", "prompt":"A symbol turns one quarter each step: up, right, down, left, up, ?", "hint":"The four directions loop in order.", "options":["UP", "RIGHT", "DOWN", "LEFT"], "answer":"RIGHT"},
				{"title":"The Expert Sequence", "prompt":"Find the next pair: AB, DE, HI, MN, ?", "hint":"The first letters step +3, +4, +5, then +6; each pair is consecutive.", "options":["RS", "ST", "TU", "UV"], "answer":"ST"},
			]
			return stages[tier]
		"door":
			var stages := [
				{"title":"Three-Digit Welcome", "prompt":"The code is the number of sides on a triangle, followed by the number of corners on a square, then the number of moons in the sky tonight.", "hint":"Use 3 sides, 4 corners, and 1 moon.", "answer":"341", "code_length":3},
				{"title":"The Reversed Rule", "prompt":"Enter four digits: 2+2, the number of primary colors, 10-7, then the corners of a triangle.", "hint":"The answers in order are 4, 3, 3, and 3.", "answer":"4333", "code_length":4},
				{"title":"Equation Door", "prompt":"Solve left to right: 18 ÷ 3, then add the number of sides on a pentagon. Enter that two-part code.", "hint":"18 ÷ 3 is 6; a pentagon has 5 sides.", "answer":"65", "code_length":2},
				{"title":"The Prime Vault", "prompt":"A three-digit code: the smallest prime, the only even prime, then the next prime after 3.", "hint":"The first primes are 2, 3, 5, 7…", "answer":"235", "code_length":3},
				{"title":"Master Lock", "prompt":"Use four digits: 2 cubed, the square root of 81, the number of factors of 6, then 5 squared minus 20.", "hint":"Evaluate each clue in order: 8, 9, 4, 5.", "answer":"8945", "code_length":4},
			]
			return stages[tier]
		"wires":
			var targets := [
				[1, 0],
				[1, 0, 1],
				[0, 1, 1, 0],
				[1, 0, 1, 0, 1],
				[0, 1, 1, 0, 1, 0],
			]
			return {"title":["Two-Wire Spark", "Color Circuit", "Switchboard Logic", "The Current Maze", "Master Circuit"][tier], "prompt":"Tap each wire to toggle its route. Match the glowing terminal pattern, then check the circuit.", "hint":"Compare each left terminal with its right-hand destination; toggle only the mismatched strands.", "wire_names":["CORAL", "TEAL", "GOLD", "BLUE", "LILAC", "MINT"].slice(0, targets[tier].size()), "answer":targets[tier].duplicate()}
		"water":
			var targets := [
				[2, 2, 2],
				[2, 2, 2, 2],
				[2, 2, 2, 2, 2],
				[2, 2, 2, 2, 2, 2],
				[2, 2, 2, 2, 2, 2, 2],
			]
			return {"title":["First Flow", "Valve Relay", "Branching Stream", "Pressure Puzzle", "Deep-Water Route"][tier], "prompt":"Rotate each pipe tile to guide water from the blue inlet to the gold tank. Check the full route when ready.", "hint":"Trace the route one tile at a time from left to right. A continuous path reaches the tank.", "answer":targets[tier].duplicate()}
		"shape":
			var targets := [1, 2, 3, 1, 2]
			return {"title":["Turn the Triangle", "Quarter-Turn Key", "Compass Piece", "Rotating Seal", "Master Shape"][tier], "prompt":"Rotate the loose piece until it matches the outline shown by the target marker.", "hint":"Each tap turns the piece one quarter-turn clockwise. The target needs %d quarter-turns." % targets[tier], "answer":targets[tier]}
		"memory":
			var sequences := [
				[0, 2, 1],
				[3, 1, 3, 0],
				[2, 0, 3, 1, 2],
				[1, 3, 0, 2, 3, 1],
				[3, 0, 2, 1, 3, 2, 0],
			]
			return {"title":["Quick Glance", "Echo Tiles", "Memory Circuit", "Long Sequence", "Perfect Recall"][tier], "prompt":"Memorize the glowing sequence. When the tiles hide, repeat it in the same order.", "hint":"The sequence is: %s" % _memory_hint(sequences[tier]), "answer":sequences[tier].duplicate(), "memory_sequence":sequences[tier].duplicate()}
		"move":
			var starts := [
				["KEY", "MAP", "ORB"],
				["STAR", "BOOK", "GEM", "MAP"],
				["ORB", "KEY", "LAMP", "RING", "MAP"],
				["CROWN", "MOON", "KEY", "GEM", "STAR"],
				["RUNE", "ORB", "CROWN", "KEY", "LAMP", "STAR"],
			]
			var goals := [
				["MAP", "ORB", "KEY"],
				["GEM", "STAR", "MAP", "BOOK"],
				["RING", "ORB", "MAP", "LAMP", "KEY"],
				["STAR", "KEY", "CROWN", "MOON", "GEM"],
				["LAMP", "CROWN", "STAR", "RUNE", "KEY", "ORB"],
			]
			return {"title":["Swap the Relics", "The Shelf Shuffle", "Keeper's Crates", "Astral Sorting", "Grand Relic Relay"][tier], "prompt":"Move one relic at a time until every piece matches the target order. Click two slots to swap, or drag a piece onto another slot.", "hint":"Target order: %s" % _join_words(goals[tier]), "pieces":starts[tier].duplicate(), "answer":goals[tier].duplicate()}
		"missing":
			var stages := [
				{"title":"The Empty Corner", "prompt":"A row follows 1, 2, 3. Which piece belongs in the empty spot?", "hint":"The count increases by one each time.", "options":["2", "3", "4", "5"], "answer":"4"},
				{"title":"Shape Grid", "prompt":"Each row gains one side: triangle, square, pentagon. What comes next?", "hint":"Count the sides: 3, 4, 5, then one more.", "options":["HEXAGON", "CIRCLE", "OCTAGON", "STAR"], "answer":"HEXAGON"},
				{"title":"Equation Slot", "prompt":"Fill the missing value: 6 × ? = 42.", "hint":"Divide 42 by 6.", "options":["5", "6", "7", "8"], "answer":"7"},
				{"title":"The Missing Pair", "prompt":"Complete the grid rule: each pair sums to 20. The visible pair is 13 and ?", "hint":"Subtract 13 from 20.", "options":["5", "6", "7", "8"], "answer":"7"},
				{"title":"Final Fragment", "prompt":"A number is missing: 2, 6, 12, 20, 30, ? The gaps grow by two.", "hint":"The gaps are +4, +6, +8, +10, then +12.", "options":["40", "42", "44", "46"], "answer":"42"},
			]
			return stages[tier]
	return {"title":"Uncatalogued Puzzle", "prompt":"Study the clues and choose the answer.", "hint":"Inspect the pattern carefully.", "options":["A", "B", "C", "D"], "answer":"A"}

static func _join_words(words: Array) -> String:
	var text := ""
	for i in range(words.size()):
		if i > 0: text += "  ·  "
		text += str(words[i])
	return text

static func _memory_hint(sequence: Array) -> String:
	var symbols := ["CIRCLE", "TRIANGLE", "DIAMOND", "STAR"]
	var names: Array[String] = []
	for value in sequence: names.append(symbols[int(value)])
	return _join_words(names)
