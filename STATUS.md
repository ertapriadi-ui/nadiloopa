# NADILOOPA — Production Status Checklist (v2.0)

**Project Codename**: NADILOOPA *(Internal working title only; not trademark-cleared)*  
**Engine**: Godot `4.7.2.stable.official.ed1daf0bf`  
**Version**: `2.1.0` (`versionCode = 3`)  
**Build Date**: 2026-11-19

## Deliverables & Acceptance Gates

| Gate | Requirement | Status | Verified Artifact Path |
|---|---|---|---|
| **A** | Installable Android Debug APK (`v2.1.0`) | **BUILT, SIGNED & INSTALLED ON `SM_S948B`** *(overwrote old `v1.0.0` via `adb install -r`, `versionCode=1 -> 3`)* | [`build/android/nadiloopa_debug.apk`](build/android/nadiloopa_debug.apk) (`nadiloopa_debug.apk`) |
| **B** | Complete editable Godot 4.7.2 project | **COMPLETE** | [`project.godot`](project.godot), [`scenes/main.tscn`](scenes/main.tscn), [`scripts/`](scripts/) |
| **C** | Editable/master visual & audio generators | **COMPLETE** | [`tools/generate_hd_assets.py`](tools/generate_hd_assets.py), [`tools/build_glossy_adaptive_icons.ps1`](tools/build_glossy_adaptive_icons.ps1), [`tools/generate_audio_assets.py`](tools/generate_audio_assets.py), [`tools/generate_100_levels.py`](tools/generate_100_levels.py), [`assets/master_sources/`](assets/master_sources/) |
| **D** | Multi-screen & multi-resolution screenshots | **COMPLETE & INSPECTED** | [`screenshots/`](screenshots/) (`13` PNGs across `720×1600`, `1080×1920`, `1080×2400`, `1440×3200`) |
| **E** | README and reproducible BUILD guide | **COMPLETE** | [`README.md`](README.md), [`BUILD.md`](BUILD.md) |
| **F** | Factual QA & 100-level simulation report | **COMPLETE** | [`QA_REPORT.md`](QA_REPORT.md), [`docs/sim_logs/level_verification_report.json`](docs/sim_logs/level_verification_report.json) |
| **G** | Asset provenance & licensing log | **COMPLETE** | [`ASSET_PROVENANCE.md`](ASSET_PROVENANCE.md) |
| **H** | Feature checklist & caveats | **COMPLETE** | [`STATUS.md`](STATUS.md) |

## Feature Checklist (v2.0)
- [x] Super-glossy 3D app icon (`icon_1024.png`, `launcher_192.png`) + Android 8+ adaptive foreground/background (`adaptive_fg_432.png`, `adaptive_bg_432.png`) centered in 66% safe zone
- [x] Adaptive `7 × 12` (`84` square cells) portrait board (`cell_px = floor(min(w/7, h/12))`) with punch-hole cutout safe-area clamping (`>= 64 px` top inset on Android / tall screens)
- [x] 6 glossy cute smiling organ characters (`Heart`, `Brain`, `Lungs`, paired `Kidneys`, `Stomach`, `Liver`) with dynamic `_happy` cheering states when chained
- [x] Signature **Endpoint Pulse** (Pass A `Care` & `Bloom` -> Pass B `Overload` & 2-HP `"2"`-crested `Armored Overload`) with localized pre-release badges (`+SHIELD`/`+PERISAI`, `+BLOOM`/`+BUNGA`, `BLOCK`/`TAHAN`, `CRACK`/`RETAK`, `-10`) and rays drawn beneath organ faces
- [x] **Nadi Loop** closed-circuit 8-way Super Pulse (`+1` Shield, `+10` Pulse, `3` bonus clears, `1.5×` chain multiplier) + `loop_danger` warning on unshielded extra hazards
- [x] **Tactical Care Dock**: `Fruit Spark` (`30`), `Clear Flow` (`25`, no-op guarded), `Rest Shield` (`40`, max-shield guarded), plus `Combo x1.2..x1.8` streak
- [x] **100 Unique-Titled Levels Across 10 Chapters** (all 100 canonical-solvable, `99/100` 3/3 multi-seed bot pass rate, `57.1%` avg move usage, `78/100` reaching calibrated 3-star bar)
- [x] **Endless Zen Mode** (wave clear banner & `+7/+8` moves), **Daily Sanctuary Challenge** (consecutive-day streak logic), **Sanctuary Almanac** (`10` cards including Bloom & Armor, Career Stats header, `10` badges with celebration banners)
- [x] 4 original stereo BGM themes (`bgm_menu_tropika`, `bgm_gameplay_nadi`, `bgm_boss_harmoni`, `bgm_victory_cerah`) + 21 staggered SFX events across `Master`/`Music`/`SFX`/`UI`
- [x] Complete EN/ID bilingual localization (`strings_en_id.json`, 0 missing keys) + high-contrast locked tabs & UI
- [x] Versioned local save (`SCHEMA_VERSION = 2`) with write-ahead + mirrored `.bak` corruption recovery
- [x] Automated headless QA suite (`432 assertions passed, 0 failed`)
- [x] Independent Game Quality Audit (`2d3c9c1f-cac4-4faa-b41b-27250875d1a1`): **6.73/10 (v1.0) -> 8.18/10 (v2.0 Initial) -> 9.14/10 (`PASS >= 9.0/10`)**
- [x] On-device USB reinstall (`versionCode=1 -> 3`), live play verification (`Qualcomm Adreno 840`, zero `logcat` errors), and device screenshot [`screenshots/device_sm_s948b_v2.png`](screenshots/device_sm_s948b_v2.png)
