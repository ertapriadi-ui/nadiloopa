class_name ChainValidator
extends RefCounted
## Validates orthogonal chain construction, backtracking, duplicate prevention, and Nadi Loop closure.

const MIN_CHAIN_LENGTH: int = 3


static func is_orthogonal(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


static func is_loop(chain: Array[Vector2i]) -> bool:
	if chain.size() < 5:
		return false
	var last := chain[chain.size() - 1]
	for i in range(0, chain.size() - 3):
		if chain[i] == last:
			return true
	return false


static func can_start_at(board: BoardState, pos: Vector2i) -> bool:
	if board == null or not BoardState.is_in_bounds(pos):
		return false
	var cell := board.get_cell(pos)
	return cell.get("kind", "") == "organ" and int(cell.get("restricted_turns", 0)) <= 0


static func try_step(board: BoardState, chain: Array[Vector2i], pos: Vector2i) -> String:
	if board == null or not BoardState.is_in_bounds(pos):
		return "invalid"
	if chain.is_empty():
		if can_start_at(board, pos):
			chain.append(pos)
			return "added"
		return "invalid"

	var last: Vector2i = chain[chain.size() - 1]
	if pos == last:
		return "ignored"

	# Always permit backtracking onto the immediately previous tile
	if chain.size() >= 2 and pos == chain[chain.size() - 2]:
		chain.pop_back()
		return "backtrack"

	# Once a Nadi Loop is closed, player must backtrack before changing direction
	if is_loop(chain):
		return "invalid"

	if not is_orthogonal(last, pos):
		return "invalid"

	var head_cell := board.get_cell(chain[0])
	var next_cell := board.get_cell(pos)
	if next_cell.get("kind", "") != "organ" or int(next_cell.get("restricted_turns", 0)) > 0:
		return "invalid"
	if str(next_cell.get("organ", "")) != str(head_cell.get("organ", "")):
		return "invalid"

	# Check if closing a Nadi Loop (connecting orthogonally back onto an earlier tile in a 4+ chain)
	if chain.has(pos):
		if chain.size() >= 4:
			for i in range(0, chain.size() - 3):
				if chain[i] == pos:
					chain.append(pos)
					return "loop"
		return "invalid"

	chain.append(pos)
	return "added"


static func is_valid_commit(board: BoardState, chain: Array[Vector2i], min_len: int = MIN_CHAIN_LENGTH) -> bool:
	if board == null or chain.size() < min_len:
		return false
	var first_cell := board.get_cell(chain[0])
	if first_cell.get("kind", "") != "organ" or int(first_cell.get("restricted_turns", 0)) > 0:
		return false
	var organ_type: String = str(first_cell.get("organ", ""))
	var seen := {}
	var has_closed_loop := false
	for i in range(chain.size()):
		var p: Vector2i = chain[i]
		if not BoardState.is_in_bounds(p):
			return false
		var c := board.get_cell(p)
		if c.get("kind", "") != "organ" or int(c.get("restricted_turns", 0)) > 0:
			return false
		if str(c.get("organ", "")) != organ_type:
			return false
		if i > 0 and not is_orthogonal(chain[i - 1], p):
			return false
		if seen.has(p):
			# Allow single loop closure only on the final tile when chain.size() >= 5
			if i == chain.size() - 1 and chain.size() >= 5 and not has_closed_loop and int(seen[p]) <= chain.size() - 4:
				has_closed_loop = true
			else:
				return false
		else:
			seen[p] = i
	return true
