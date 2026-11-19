# BUILD & REPRODUCIBILITY GUIDE

## Verified Toolchain Versions
- **Godot Engine**: `4.7.2.stable.official.ed1daf0bf` (`H:\dev\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe`)
- **Godot Export Templates**: `4.7.2.stable` (`C:\Users\User\AppData\Roaming\Godot\export_templates\4.7.2.stable\`)
- **JDK**: OpenJDK Temurin `17.0.21+9` (`H:\dev\android\jdk17\jdk-17.0.21+9`)
- **Android SDK**: `H:\dev\android\sdk` (`build-tools\35.0.1`, `platforms\android-35`, `platform-tools`)
- **Python**: `3.12` (used only for asset/audio generation scripts in `tools/`, standard library only)

## 1. Rebuilding Generated Assets (Optional)
All sprites, icons, and WAV audio files are already committed in `assets/`. To regenerate from scratch:
```powershell
python tools/generate_hd_assets.py
python tools/generate_audio_assets.py
```

## 2. Running Automated Headless Tests & 20-Level Simulations
```powershell
& "H:\dev\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path "L:\My Drive\Games Development" -s res://tests/test_suite.gd
```

## 3. Capturing Multi-Resolution Visual Screenshots
```powershell
& "H:\dev\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe" --path "L:\My Drive\Games Development" --windowed --resolution 450x800 -s res://tools/capture_screenshots.gd
```

## 4. Exporting the Android Debug APK
Ensure Godot Editor Settings (`editor_settings-4.7.tres`) point to JDK 17, Android SDK, and your local debug keystore (`debug.keystore`). Then run:
```powershell
& "H:\dev\godot_4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path "L:\My Drive\Games Development" --export-debug "Android Debug" "build/android/nadiloopa_debug.apk"
```

## 5. Verifying & Installing the APK
Verify APK signature and manifest badging:
```powershell
& "H:\dev\android\sdk\build-tools\35.0.1\apksigner.bat" verify --verbose --print-certs "build/android/nadiloopa_debug.apk"
& "H:\dev\android\sdk\build-tools\35.0.1\aapt2.exe" dump badging "build/android/nadiloopa_debug.apk"
```

Install onto a connected USB Android device or running emulator with ADB debugging enabled:
```powershell
& "H:\dev\android\sdk\platform-tools\adb.exe" install -r "build/android/nadiloopa_debug.apk"
& "H:\dev\android\sdk\platform-tools\adb.exe" shell am start -n com.nadiloopa.puzzle/com.godot.game.GodotApp
```

## Replacing Working Title / Package Identity
1. Edit `codename` in `data/game_config.json` and `APP_TITLE` in `data/translations/strings_en_id.json`.
2. Update `application/config/name` in `project.godot`.
3. Update `package/unique_name` and `package/name` in `export_presets.cfg`.
4. Replace icon PNGs in `assets/icons/`.
