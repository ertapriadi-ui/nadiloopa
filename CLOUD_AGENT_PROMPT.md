# Panduan & Prompt Memulai Agen di Cloud (`ertapriadi-ui/nadiloopa`)

Gunakan salah satu prompt di bawah ini untuk langsung memulai agen coding di cloud (seperti GitHub Copilot / Jules / Antigravity Cloud / Codex / Claude Code Web) pada repositori **`https://github.com/ertapriadi-ui/nadiloopa`**.

---

## Prompt 1 — Prompt Induk (1 Agen Cloud / Koordinator Utama)

> **Salin & tempel prompt berikut ke agen cloud:**
```text
Kerjakan tugas pada repositori GitHub `ertapriadi-ui/nadiloopa` (game puzzle Android Godot 4.7.2).

Langkah wajib pertama sebelum mengubah apa pun:
1. Clone atau pull branch `main` terbaru dari `https://github.com/ertapriadi-ui/nadiloopa.git`.
2. Baca file `AGENTS.md`, `STATUS.md`, dan `project.godot` untuk memahami arsitektur 7 maskot organ, grid dinamis Easy (5x7) / Medium (6x9) / Hard (7x12), serta mekanik Nadi Loop & Sayur/Buah ikut pecah.
3. Buat branch baru `stream/<nama-alur>-<fitur>` dari `main` agar kerja tetap rapi dan tidak bentrok.
4. Setelah melakukan perubahan:
   - Pastikan kesetaraan bahasa EN/ID dengan `LocalizationManager.validate_parity()`.
   - Jalankan `godot --headless --path . --import --quit` lalu `godot --headless --path . -s res://tests/test_suite.gd` dan pastikan SELURUH tes & simulasi 100 level lulus dengan `0 failed`.
   - Jika menambah fitur baru, tambahkan unit test baru di `tests/test_suite.gd`.
   - Commit dengan pesan jelas dan push branch untuk memicu GitHub Actions (`CI & Android APK`) agar APK Android terbaru otomatis ter-build di cloud, lalu ajukan Pull Request ke `main`.

Tugas yang ingin dikerjakan saat ini:
[TULISKAN FITUR / PERBAIKAN YANG ANDA INGINKAN DI SINI, misalnya: "Tambahkan Cloud Save & Papan Peringkat Global" atau "Tambahkan 20 level baru Bab 11"]
```

---

## Prompt 2 — Prompt Kerja Paralel Multi-Alur (Banyak Agen Cloud Sekaligus)

Jika Anda ingin menjalankan **3 agen cloud sekaligus secara paralel** tanpa konflik file:

### Agen Alur A (Gameplay, Mekanik & 100+ Level)
```text
Kamu adalah agen Alur A (Gameplay & Level Design) di repo `ertapriadi-ui/nadiloopa`.
Baca `AGENTS.md`. Buat branch `stream/gameplay-update` dari `main`.
Area milikmu: `scripts/core/`, `tools/generate_100_levels.py`, `data/levels/`, dan `tests/test_suite.gd`.
Jangan ubah layout UI di `scripts/ui/main_controller.gd` kecuali diminta.
Implementasikan: [JELASKAN TUGAS GAMEPLAY/LEVEL].
Pastikan `godot --headless --path . -s res://tests/test_suite.gd` lulus 100% (0 failed), lalu push branch `stream/gameplay-update` & buat PR ke `main`.
```

### Agen Alur B (UI/UX Minimalis, Animasi & Visual)
```text
Kamu adalah agen Alur B (UI/UX, Animasi & Aset Visual) di repo `ertapriadi-ui/nadiloopa`.
Baca `AGENTS.md`. Buat branch `stream/ui-polish` dari `main`.
Area milikmu: `scripts/ui/`, `assets/`, `data/translations/strings_en_id.json`, dan `tools/capture_screenshots.gd`.
Pertahankan gaya UI minimalis huruf besar (minimal 24px-34px) dan sinkronkan terjemahan `"en"` dan `"id"`.
Implementasikan: [JELASKAN TUGAS UI/ANIMASI].
Jalankan `godot --headless --path . --import --quit` dan `godot --headless --path . -s res://tests/test_suite.gd` (harus 0 failed), lalu push branch `stream/ui-polish` & buat PR ke `main`.
```

### Agen Alur C (Cloud Sync, CI/CD & Rilis APK Otomatis)
```text
Kamu adalah agen Alur C (Cloud Backend, Sinkronisasi Save & Release DevOps) di repo `ertapriadi-ui/nadiloopa`.
Baca `AGENTS.md`. Buat branch `stream/cloud-sync` dari `main`.
Area milikmu: `scripts/autoload/save_manager.gd`, `.github/workflows/`, `export_presets.cfg`, dan `project.godot`.
Implementasikan: [JELASKAN TUGAS CLOUD, misalnya Export Web HTML5 / Cloud Save REST Sync / Bump version & Rilis APK ke GitHub Releases].
Verifikasi semua test di `tests/test_suite.gd` (harus 0 failed), pastikan workflow `.github/workflows/ci_and_apk.yml` hijau saat di-push, lalu buat PR ke `main`.
```

---

## Cara Sinkronisasi Komputer Lokal <-> Cloud Setelah Agen Cloud Bekerja
Kapan saja ada pembaruan di GitHub yang sudah di-merge ke `main`:
1. Di komputer lokal (jika ingin sinkronisasi):
   ```powershell
   git pull origin main
   ```
2. Untuk mengunduh **APK terbaru langsung di HP Android tanpa PC/kabel**, buka tab **Releases** atau **Actions -> Artifacts** pada halaman GitHub repositori `https://github.com/ertapriadi-ui/nadiloopa`.
