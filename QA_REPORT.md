# NADILOOPA — QA, Verification & Simulation Report (v2.0)

## 1. Test Environment
- **Host OS**: Windows (`win64`)
- **Godot Engine**: `4.7.2.stable.official.ed1daf0bf` (`H:\dev\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe`)
- **JDK**: OpenJDK Temurin `17.0.21+9` (`H:\dev\android\jdk17\jdk-17.0.21+9`)
- **Android SDK**: `H:\dev\android\sdk` (`build-tools 35.0.1 / 36.1.0`, `platforms/android-35 / android-36`, `platform-tools`)
- **Desktop GPU Renderer (Visual Verification)**: NVIDIA GeForce RTX 4080 SUPER (`OpenGL API 3.3.0`, GL Compatibility mode)

---

## 2. Automated Headless QA Suite (`tests/test_suite.gd`)
Command executed after all v2.0 gameplay, localization, balance, and save fixes:
```powershell
& "H:\dev\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path "L:\My Drive\Games Development" -s res://tests/test_suite.gd
```
**Result**: **`432 assertions passed, 0 failed`** (Exit code `0`).

### Verified Test Coverage
1. **Grid Bounds & 84 Slots**: `COLS=7`, `ROWS=12`, `TOTAL_CELLS=84`, clipped orthogonal & 8-way neighbors, bounds safety.
2. **Chain Validation, Backtracking & Nadi Loop**: Orthogonal chaining, `0`-move short cancel, typed `Array[Vector2i]` signal emission (`TouchInputController`), `2×2` closed-circuit Nadi Loop (`is_loop = true`, 8-way neighbors, `+1` Shield, `+10` Pulse, `3` bonus clears), `overload_cracked` preview on 2-HP Armored Overloads, and `loop_danger` warning when unshielded Overloads sit inside an 8-way Loop blast.
3. **Deterministic Pre-Refill Endpoint & Hazard Logic**: Pass A (`Care` & `Vitality Bloom` `+20` Energy / `+6` Pulse) -> Pass B (`Overload` 1-HP clear vs 2-HP armor crack `2 -> 1` vs `-10` Pulse + `<=2` cell lock for `1` turn with automatic expiry).
4. **Tactical Care Abilities & No-Op Guards**: `Fruit Spark` (objective-weighted 4-tile conversion), `Clear Flow` (`+12` Pulse + unlock + weaken armor, blocked with `0` Energy spent when board clean & Pulse 100), `Rest Shield` (`+1` Shield + spawns Care tile, blocked cleanly at `2/2` max shields).
5. **Gravity, Seeded Refill & Reshuffle**: Deterministic seeded drop/refill (`min_care_on_board` & `min_overload_on_board` replenishment) + checkerboard deadboard reshuffle.
6. **Persistence, Mirrored Backup Recovery & Daily Streaks**: `SCHEMA_VERSION = 2` canonical checksum, write-ahead + mirrored `.bak` recovery preserving achievements, `record_daily_win` consecutive-day increment (`2026-11-17 -> 2026-11-18` => streak `2`) and skipped-day reset (`-> 2026-11-20` => streak `1`), plus `reset_progress_keep_settings()`.
7. **Bilingual Parity & Assets**: Zero missing EN/ID keys in `strings_en_id.json`; existence verified for all `12` normal/`_happy` organ sprites, `9` special/ability icons, `4` BGM WAVs, and `21` SFX WAVs.

---

## 3. 100-Level Automated Solvability & Balance Simulation
Full machine-readable log: [`docs/sim_logs/level_verification_report.json`](docs/sim_logs/level_verification_report.json) (3 seeded runs per stage × 100 stages = 300 full simulations).

- **Canonical Seeds Won**: **`100 / 100` stages (`100%`)**
- **3/3 Multi-Seed Wins**: **`99 / 100` stages** (all 100 stages `>= 66%` win rate)
- **Average Move Budget Utilization**: **`57.1%`** (tightened from overly loose `31%`, creating engaging mid/late tension across Chapters 3–10; Stage 100 finishes in `16.0 / 24` moves = `66.7%`)
- **Calibrated 3-Star Achievability**: **`78 / 100` stages** reached the 3-star threshold in smart-bot runs (`[s1, 1.22*s1, 1.48*s1]`).

---

## 4. Visual, Multi-Resolution & UI Verification
Captured via `tools/capture_screenshots.gd` (`13` PNGs after final Godot asset re-import):
- **`1080 × 2400` (`03`–`09`, `res_1080x2400.png`)**: `cell_px = 148` (`1036 × 1776`), safe top padding `64 px` clearing punch-hole camera zones.
- **`1080 × 1920` (`res_1080x1920.png`)**: `cell_px = 132` (`924 × 1584`), `0` clipping across HUD, board, or Tactical Care Dock.
- **`720 × 1600`** & **`1440 × 3200`**: Clean `canvas_items` scaling, sharp sprites & `Inter` font rendering.
- **Visual Defects Fixed During Iteration**:
  1. Rebuilt `adaptive_fg_432.png` & `adaptive_bg_432.png` from glossy `icon_glossy_v2.jpg` instead of v1 procedural art.
  2. Replaced `"1"`-die armor badge on `special_overload_armor.png` with an embossed blue-gold `"2"` shield crest.
  3. Moved Endpoint Pulse rays/borders beneath `_tile_layer` so lines never cross smiling faces while localized pill badges (`+SHIELD`, `CRACK`, `BLOCK`, `+BLOOM`, `-10`) stay crisp above tiles.
  4. Stacked multi-event endpoint floating popups vertically (`if` instead of `elif`) and localized all board badges & floating texts (`strings_en_id.json`).
  5. Added Vitality Bloom & Armored Overload cards + persistent Career Sanctuary Record card to Almanac (`08`, `09`), high-contrast locked Chapter `6–10` tabs & `[BOSS]` prefix (`02`), and removed duplicate `Main Menu` button on Daily Win modal.

---

## 5. Audio Verification (`tools/generate_audio_assets.py`)
- **4 Original BGM Tracks** (`44.1 kHz` 16-bit stereo WAV, `loop_jump <= 0.0005`, zero clipping): `bgm_menu_tropika.wav` (`17.78s`), `bgm_gameplay_nadi.wav` (`36.92s`), `bgm_boss_harmoni.wav` (`24.41s`), `bgm_victory_cerah.wav` (`6.80s`).
- **21 Distinct SFX Events** (`0.12s–0.90s`) with staggered turn-resolution triggering (`0.00s` clear -> `0.08s` pulse/event -> `0.17s` refill drop -> `0.25s` score/banner) to keep the mix clear.

---

## 6. v2.1.0 Android APK Build, Signing & On-Device Verification (`SM_S948B`)
- **Export Command**:
  `& "H:\dev\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path "L:\My Drive\Games Development" --export-debug "Android Debug" "build/android/nadiloopa_debug.apk"` (Exit code `0`)
- **Output File**: [`build/android/nadiloopa_debug.apk`](build/android/nadiloopa_debug.apk) (`67,777,990` bytes)
- **`apksigner verify --verbose`**: `Verifies` (`v2 scheme: true`, `v3 scheme: true`)
- **`aapt2 dump badging`**:
  - `package: name='com.nadiloopa.puzzle' versionCode='3' versionName='2.1.0'`
  - `minSdkVersion:'24'`, `targetSdkVersion:'36'`, `application-label:'NADILOOPA'`
- **Matching App & Adaptive Icons Rebuilt**: Regenerated [`icon_1024.png`](assets/icons/icon_1024.png), [`launcher_192.png`](assets/icons/launcher_192.png), [`adaptive_fg_432.png`](assets/icons/adaptive_fg_432.png), and [`adaptive_bg_432.png`](assets/icons/adaptive_bg_432.png) via `tools/generate_hd_assets.py icons` using the exact glossy in-game Smiling Heart mascot.
- **Physical Device Install & Launch (`SM_S948B` / `RRGL204EBQF`)**:
  - Installed in-place over previous app via `adb -s RRGL204EBQF install -r` (`versionCode=1 -> 3`, `Success`).
  - Cold-launched `com.nadiloopa.puzzle/com.godot.game.GodotAppLauncher` (`Status: ok`, `TotalTime: 190 ms`, `Qualcomm - Adreno (TM) 840`), zero `godot` / `AndroidRuntime` errors in `logcat`, and captured live gameplay screenshot [`screenshots/device_sm_s948b_v2.png`](screenshots/device_sm_s948b_v2.png).

---

## 7. Independent Evaluator Progression
Audited independently by subagent `research` (`2d3c9c1f-cac4-4faa-b41b-27250875d1a1`):
- **v1.0 Baseline Audit**: **6.73 / 10.0**
- **v2.0 Initial Audit**: **8.18 / 10.0** (`+1.45` — flagged stale v1 APK/adaptive icon, armor preview badge, in-board localization, balance tuning, and Almanac/Endless/Audio polish)
- **v2.0 Final Re-Audit**: **`9.14 / 10.0` (`PASS >= 9.0/10`)** (`+2.41` vs v1.0, `+0.96` vs v2.0 Initial):
  - App Icon Glossiness & Cute Smiling Organ Art (`20%`): `6.5` -> `8.3` -> **`9.2`**
  - Core Gameplay Depth (`20%`): `7.2` -> `8.4` -> **`9.3`**
  - 100-Level Progression, Hazard Variety & Balance (`20%`): `7.0` -> `7.8` -> **`9.0`**
  - Long-Term Replayability (`15%`): `4.5` -> `8.2` -> **`9.1`**
  - UI/UX, Safe Area Ergonomics & Bilingual Polish (`15%`): `7.8` -> `8.2` -> **`9.2`**
  - Original Audio & Visual Juice/VFX (`10%`): `7.4` -> `8.2` -> **`8.9`**
  - *Minor non-blocking notes logged by auditor*: `data/game_config.json` still shows `"version": "1.0.0"` and `BUILD.md` references v1.0 20-level docs; `combo_banner` SFX inside `board_renderer.gd` triggers at `t=0` with `match_large`. (Physical `SM_S948B` hardware install & launch was subsequently completed cleanly in v2.1.0.)
