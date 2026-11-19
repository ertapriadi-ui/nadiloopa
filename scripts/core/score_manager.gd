class_name ScoreManager
extends RefCounted
## Score, combo scaling, remaining-move victory bonus, and 1-3 star calculation.


static func calculate_chain_score(chain_len: int, base_tile_score: int = 25) -> int:
	if chain_len < 3:
		return 0
	var base := chain_len * base_tile_score
	var extra := maxi(0, chain_len - 3)
	var combo_bonus := extra * extra * 18
	return base + combo_bonus


static func calculate_move_bonus(moves_left: int, per_move_bonus: int = 120) -> int:
	return maxi(0, moves_left) * per_move_bonus


static func calculate_stars(total_score: int, thresholds: Array) -> int:
	if thresholds.size() < 3:
		return 1
	if total_score >= int(thresholds[2]):
		return 3
	if total_score >= int(thresholds[1]):
		return 2
	return 1
