# NADILOOPA (v2.0)

> **Working Title Notice**: `NADILOOPA` is an internal project codename only and has not undergone trademark clearance. Package identity, display title, subtitle, and launcher icons are centrally configurable in `data/game_config.json`, `data/translations/strings_en_id.json`, and `export_presets.cfg`.

A warm, family-friendly, portrait one-finger chain-puzzle game built in **Godot 4.7.2** for **Android**, featuring **Endpoint Pulse** & **8-Way Nadi Loop** tactical puzzle mechanics, **100 unique-titled levels across 10 chapters**, **6 glossy smiling organ characters**, **3 Tactical Care Abilities**, **Endless Zen & Daily Sanctuary modes**, **Sanctuary Almanac & 10 Badges**, and **4 original BGM + 21 staggered SFX**.

## Key Features (v2.0)
- **Glossy 3D App Icon & Android Adaptive Launcher Icons**: Built from `assets/master_sources/icon_glossy_v2.jpg` (`icon_1024.png`, `launcher_192.png`, `adaptive_fg_432.png`, `adaptive_bg_432.png`) spotlighting smiling 3D Heart, Brain, and Twin Kidneys inside emerald glow.
- **Adaptive `7 × 12` Portrait Grid (84 Square Cells)**: Runtime `cell_px = floor(min(usable_width / 7, usable_height / 12))` guarantees strictly square cells across `720×1600`, `1080×1920`, `1080×2400`, `1440×3200`, and punch-hole camera cutouts.
- **6 Cute Glossy Smiling Organ Characters (Normal & Happy Selected States)**:
  - **Heart** (`heart`), **Brain** (`brain`), **Lungs** (`lungs`), paired **Twin Kidneys** (`kidneys`), **Stomach** (`stomach`, Ch 3+), and **Liver** (`liver`, Ch 5+), each with expressive glossy D-smiles and dynamic `_happy` cheering sprites while chained.
- **Signature Endpoint Pulse & 8-Way Nadi Loop Mechanics**:
  - Connect `3+` orthogonally adjacent matching smiling organs; backtrack smoothly before finger release.
  - **Nadi Loop**: Looping back onto an earlier tile in a `4+` chain unleashes an **8-Way Super Pulse** (`+1` Shield charge, `+10` Pulse Meter, `3` bonus matching organ clears anywhere on the board, `1.5x` score multiplier) while still warning (`loop_danger`) if extra unshielded Overloads lie in the 8-way blast.
  - **Pre-Release Outcome Preview**: Highlights rays behind tiles and crisp localized badges (`+SHIELD`/`+PERISAI`, `+BLOOM`/`+BUNGA`, `BLOCK`/`TAHAN`, `CRACK`/`RETAK`, `-10`) **before** releasing your finger.
  - **Deterministic Pre-Refill Evaluation**: **Pass A** activates adjacent green **Care** shields & golden **Vitality Blooms** (`+20` Care Energy, `+6` Pulse) first; **Pass B** resolves standard (1-HP) and **Armored (`"2"`-crest 2-HP)** **Overload** hazards second (replenished dynamically via `min_overload_on_board`).
- **Tactical Care Dock & Harmony Combo Streak**:
  - Chain clears & Blooms charge `0–100` Care Energy without costing moves:
    - **Fruit Spark (30)**: Converts up to 4 needed objective organ tiles.
    - **Clear Flow (25)**: Clears all cell locks, weakens 2-HP Armored Overloads, and restores `+12` Pulse (guarded against wasted no-op casts).
    - **Rest Shield (40)**: Grants `+1` Shield (when below max `2/2`) and places a green Care tile.
  - Consecutive `4+` chains or Nadi Loops build a `Combo x1.2..x1.8` score streak.
- **100 Unique Stages + Endless Zen + Daily Sanctuary + Almanac**:
  - **100 Handcrafted Stages Across 10 Chapters** (`Tropical Dawn` through `Grand Harmony`), each with distinct EN/ID titles, calibrated 1–3 star thresholds, and `[BOSS]` finale encounters.
  - **Endless Zen Mode**: Multi-wave survival marathon carrying score, Energy, Shields, Streak, and `+7/+8` move wave rewards.
  - **Daily Sanctuary Challenge**: Deterministic daily seeded board with consecutive-day streak tracking.
  - **Sanctuary Almanac & Career Record**: 10 illustrated EN/ID guide cards (including Vitality Bloom & 2-HP Armored Overload), live Career Stats record, and 10 Achievement Badges with celebration banners.
- **Original Audio**: 4 stereo BGM tracks (`bgm_menu_tropika`, `bgm_gameplay_nadi`, `bgm_boss_harmoni`, `bgm_victory_cerah`) and 21 staggered pitch-scaled SFX events across `Master`, `Music`, `SFX`, and `UI` buses.
- **Offline-First & Responsible Health Communication**: Zero network access, zero ads/IAP, versioned save (`user://nadiloopa_save_v1.json`, `SCHEMA_VERSION = 2`) with write-ahead + mirrored `.bak` recovery. Pulse Meter (`0–100`) is purely a fictional game resource.

## Project Structure
- `project.godot`, `default_bus_layout.tres`, `export_presets.cfg`, `scenes/main.tscn`
- `data/` — `game_config.json`, `levels/levels_v1.json` (100 levels), `translations/strings_en_id.json` (`en` / `id` parity)
- `scripts/autoload/` — `game_manager.gd`, `save_manager.gd`, `localization_manager.gd`, `audio_manager.gd`
- `scripts/core/` — `board_state.gd`, `chain_validator.gd`, `pulse_system.gd`, `booster_system.gd`, `hazard_system.gd`, `chain_resolver.gd`, `score_manager.gd`, `level_manager.gd`
- `scripts/ui/` — `board_renderer.gd`, `touch_input_controller.gd`, `vfx_controller.gd`, `main_controller.gd`
- `assets/` — 256×256 sprites, 512×512 masters, 1080×2400 tropical backdrops, 44.1 kHz stereo WAVs (4 BGM + 21 SFX), Inter OFL fonts, v2 glossy & adaptive launcher icons
- `tests/test_suite.gd` — Automated headless QA & 100-level simulation runner (`432 assertions`)
- `tools/` — `generate_hd_assets.py`, `generate_audio_assets.py`, `generate_100_levels.py`, `build_glossy_adaptive_icons.ps1`, `capture_screenshots.gd`
- `docs/` — `GDD.md`, `sim_logs/level_verification_report.json`
- `build/android/nadiloopa_debug.apk` — Compiled, v2/v3 signed Android debug APK (`versionCode=2`, `versionName="2.0.0"`)

## Additional Documentation
- [GDD](docs/GDD.md)
- [Build & Installation Guide](BUILD.md)
- [QA Report](QA_REPORT.md)
- [Asset Provenance](ASSET_PROVENANCE.md)
- [Production Status](STATUS.md)
