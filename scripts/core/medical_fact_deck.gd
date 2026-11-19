class_name MedicalFactDeck
extends RefCounted
## Shuffled non-repeating deck of 300+ bilingual medical & organ health flashcards.

const FACTS_PATH := "res://data/medical_facts_300.json"

static var _cached_facts: Array = []


static func get_all_facts() -> Array:
	if not _cached_facts.is_empty():
		return _cached_facts
	if not FileAccess.file_exists(FACTS_PATH):
		return []
	var f := FileAccess.open(FACTS_PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY and typeof(parsed.get("facts", null)) == TYPE_ARRAY:
		_cached_facts = parsed["facts"]
	return _cached_facts


static func get_fact_count() -> int:
	return get_all_facts().size()


static func _make_shuffled_order(count: int, rng: RandomNumberGenerator) -> Array:
	var order: Array = []
	order.resize(count)
	for i in range(count):
		order[i] = i
	# Fisher-Yates shuffle
	for i in range(count - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	return order


static func draw_next_fact(save_node: Node = null, rng: RandomNumberGenerator = null) -> Dictionary:
	var facts := get_all_facts()
	var total := facts.size()
	if total == 0:
		return {}

	var use_rng := rng
	if use_rng == null:
		use_rng = RandomNumberGenerator.new()
		use_rng.randomize()

	var order: Array = []
	var cursor: int = 0
	if save_node != null and save_node.has_method("get_fact_deck_state"):
		var st: Dictionary = save_node.get_fact_deck_state()
		if typeof(st.get("order", null)) == TYPE_ARRAY:
			order = st["order"]
		cursor = int(st.get("cursor", 0))

	if order.size() != total or cursor < 0 or cursor >= total:
		order = _make_shuffled_order(total, use_rng)
		cursor = 0

	var fact_idx := clampi(int(order[cursor]), 0, total - 1)
	var fact: Dictionary = (facts[fact_idx] as Dictionary).duplicate(true)
	fact["deck_pos"] = cursor + 1
	fact["deck_total"] = total

	cursor += 1
	if cursor >= total:
		order = _make_shuffled_order(total, use_rng)
		cursor = 0

	if save_node != null and save_node.has_method("set_fact_deck_state"):
		save_node.set_fact_deck_state(order, cursor)

	return fact
