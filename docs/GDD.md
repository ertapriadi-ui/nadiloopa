# NADILOOPA — Game Design Document & Production Specification (v2.0)

> **Working Title Notice**: `NADILOOPA` is an internal codename and working title only. It has not undergone trademark clearance. App title, subtitle, package ID, and icon assets are centralized in `res://data/game_config.json` and `export_presets.cfg`.

## 1. Core Concept
NADILOOPA is a family-friendly portrait one-finger chain-puzzle game built in **Godot 4.7.2** for Android (`1080×2400` design reference, responsive across `720×1600`, `1080×1920`, `1080×2400`, `1440×3200`, and camera punch-hole safe areas).

- **Primary Grid**: Fixed **7 columns × 12 rows = 84 logical square cells**.
- **Runtime Cell Sizing**:
  `cell_px = floor(min(usable_board_width / 7.0, usable_board_height / 12.0))`
  The board centers inside the host container so cells remain strictly square and never stretch or clip.
- **Glossy Smiling Organ Characters (6 Families)**:
  1. **Heart** (`heart`) — Glossy coral-rose heart with bright smiling eyes, happy cheek highlights, and sprouting leaf.
  2. **Brain** (`brain`) — Lavender scalloped cloud-brain with joyful expression and golden focus star.
  3. **Lungs** (`lungs`) — Sky-cyan twin lobes joined by a bronchial bridge.
  4. **Twin Kidneys** (`kidneys`) — Amber-gold inseparable pair connected by a central bridge, both smiling.
  5. **Stomach** (`stomach`, Ch 3+ / Stage 21+) — Warm peach-orange cozy energy organ.
  6. **Liver** (`liver`, Ch 5+ / Stage 41+) — Berry-magenta clean filter organ paired with Golden Vitality Blooms.
  Every organ swaps dynamically to its `_happy` cheering expression while included in an active drag chain.
- **Special Tiles**:
  1. **Care Shield** (`care`) — Emerald octagonal shield with veggie mascot (`+1` Shield max `2`, `+8` Pulse).
  2. **Vitality Bloom** (`bloom`, Ch 5+ / Bosses) — Golden smiling sun-flower granting `+20` Care Energy, `+6` Pulse, and `+250` pts on endpoint pulse.
  3. **Overload** (`overload` variants: burger, soda, snack; plus 2-HP **Armored Overload** with embossed `"2"` blue-gold shield crest).

## 2. Chain Rules, Nadi Loop & Tactical Abilities
- **States**: `READY`, `SELECTING`, `RESOLVING`, `REFILLING`, `WIN`, `LOSE`, `PAUSED`.
- **Chain & Nadi Loop Validation**:
  - Touch and drag across orthogonally adjacent matching unrestricted organs (`min_len = 3`). Backtracking pops cleanly; canceling `< 3` costs `0` moves.
  - **Nadi Loop**: Dragging a `4+` chain back onto an earlier tile closes a circuit, triggering an **8-Way Super Pulse** around the endpoint (`+1` Shield, `+10` Pulse, up to `3` bonus matching organ clears anywhere on the board, `1.5×` chain score multiplier).
- **Endpoint Pulse Resolution Order (Pre-Refill Snapshot)**:
  1. Lock input (`RESOLVING`) and apply Harmony Combo Streak multiplier (`1.0×` up to `1.8×` on consecutive `4+`/Loop chains).
  2. **Pass A (Boosters First)**: Adjacent `care` and `bloom` tiles trigger first (Shield charges gained in Pass A protect Pass B on the same turn).
  3. **Pass B (Hazards Second)**: Adjacent `overload` tiles trigger:
     - If `shield_charges > 0`: consumes `1` Shield; 2-HP Armored Overloads crack `2 -> 1` (`ARMOR CRACK!` / `LAPISAN RETAK!`); 1-HP Overloads clear cleanly (`BLOCKED!` / `DITAHAN!`).
     - If `shield_charges == 0`: deducts `10` fictional Pulse Meter points and restricts up to `2` eligible adjacent organ cells for `1` move.
  4. Pre-release `preview_endpoint()` accurately shows `CRACK` on 2-HP Armored Overloads and flags `loop_danger` if unshielded Overloads sit within an 8-way Loop blast.
  5. Decrement prior restrictions (`1` move expiry), decrement `moves_left`, refill top rows deterministically (replenishing `min_care_on_board` and `min_overload_on_board` cleanly), and reshuffle deadlocked boards automatically.
- **Tactical Care Dock (`0` Move Cost)**:
  - **Fruit Spark (`30` Energy)**: Converts up to 4 needed objective tiles.
  - **Clear Flow (`25` Energy)**: Removes all tile locks, weakens 2-HP Armored Overloads, and heals `+12` Pulse (blocked cleanly if no effect needed).
  - **Rest Shield (`40` Energy)**: Adds `+1` Shield (guarded if already `2/2`) and places a green Care tile.

## 3. Modes & 100-Level Progression
- **100 Campaign Stages Across 10 Named Chapters** (`1–10` *Tropical Dawn* through `91–100` *Grand Harmony*), each with a unique EN/ID stage title, `[BOSS]` encounter every 10th level, balanced target curves (~57.1% bot move usage), and calibrated 1–3★ thresholds.
- **Endless Zen Mode**: Multi-wave survival marathon with Boss waves every 5th wave and `+7`/`+8` move rewards.
- **Daily Sanctuary Challenge**: Seeded daily board with consecutive-day streak tracking.
- **Sanctuary Almanac & 10 Badges**: 10 illustrated guide cards, persistent career statistics (`total_chains`, `total_loops`, `total_abilities_used`, `total_overloads_cleared`), and 10 achievement badges with celebratory unlock banners.

## 4. Responsible Health Communication
- **Pulse Meter (`0–100`)**, **Care Shields**, **Vitality Blooms**, and **Overload** hazards are purely fictional puzzle mechanics and never measure vital signs or make clinical claims.
