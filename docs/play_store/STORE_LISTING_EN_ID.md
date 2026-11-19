# NADILOOPA — Google Play Store Listing & Release Guide

## 1. Store Listing Copy (Primary: English)

- **App Name (max 30 chars):** `NADILOOPA: Organ Pulse Puzzle`
- **Category:** `Games → Puzzle` (Do NOT select Medical)
- **Short Description (max 80 chars):**
  `Link 3+ smiling 3D organs, trigger Nadi Loops, dodge toxic habits & learn facts!`
- **Full Description (EN):**
  Keep your body's harmony alive in **NADILOOPA**, a cheerful 3D chain-link puzzle adventure starring 7 heroic smiling organs: **Heart, Brain, Lungs, Kidneys, Stomach, Pancreas, and Muscle**!

  ### How to Play
  - **Link 3+ Matching 3D Organs:** Drag orthogonally across glossy gem-styled organ tiles to collect targets and build combos.
  - **Close a Nadi Loop:** Loop your 4+ chain back onto an earlier tile to unleash an 8-Way Super Pulse (+1 Shield, +10 Pulse, bonus clears, and 1.5× score!).
  - **Mega Combos & Detox Bomb:** Chain 8+ for a **Super Nova** cross blast or 10+ for a **Mega Blast** full board reset! Spend Care Energy on **Detox Bomb**, **Fruit Spark**, **Clear Flow**, and **Rest Shield** without spending a move.
  - **Survive Dynamic Lifestyle Events:** Watch out for Wildfire Smoke, Fast Food Binges, Binge Drinking, All-Nighter Fatigue, Screen Marathons, and Second-Hand Smoke!
  - **330 Shuffled Health & Organ Facts:** Discover a fresh, non-repeating bite-sized educational fact about how your organs work every time you start a stage!
  - **Organ Upgrade Lab:** Earn Wellness Coins to permanently upgrade all 7 organs up to Lv. 5 for lasting score boosts.
  - **100 Handcrafted Stages across 10 Scenic Biomes + Endless Zen + Daily Challenge:** Play across 10 unique tropical & nature backdrops with natural terrain obstacles (rocks, fallen logs, mini islands) and choose **Easy (5×7)**, **Medium (6×9)**, or **Hard (7×12)** grid sizes anytime.
  - **Free 15 Minutes Every Day + dr. Erta Pass:** Enjoy all features free for 15 minutes every single day (zero ads!), or subscribe to **dr. Erta Pass** (Monthly / Yearly) for unlimited play across NADILOOPA and all dr. Erta apps & games with 1 account.

  *Note: NADILOOPA is a casual entertainment puzzle game. Its fictional Pulse Meter and 330 general wellness facts are for fun and general awareness only and do not provide medical diagnosis or advice.*

---

## 2. Teks Play Store (Bahasa Indonesia)

- **Nama Aplikasi:** `NADILOOPA: Puzzle Organ Tubuh`
- **Deskripsi Singkat (maks 80 karakter):**
  `Hubungkan 3+ organ 3D ceria, picu Nadi Loop, hadang racun & baca 330 fakta seru!`
- **Deskripsi Lengkap (ID):**
  Jaga harmoni tubuhmu di **NADILOOPA**, game puzzle rantai 3D penuh warna bersama 7 pahlawan organ tersenyum: **Jantung, Otak, Paru-paru, Ginjal, Lambung, Pankreas, dan Otot**!

  ### Fitur Unggulan
  - **Hubungkan 3+ Organ 3D Mengkilap:** Seret untuk memanen target organ, panen Sayur & Buah antioksidan, dan raih kombo besar.
  - **Nadi Loop & Ledakan Mega:** Tutup lingkaran untuk Denyut Super 8-Arah, rangkai 8+ untuk **Super Nova**, atau 10+ untuk **Mega Blast Reset Papan**!
  - **Event Gaya Hidup Berbahaya:** Hadapi tantangan mendadak seperti Kabut Asap, Pesta Fast Food, Minum Miras, Begadang, Nonton Marathon, dan Asap Rokok!
  - **330 Fakta Kesehatan Teracak:** Baca fakta unik non-berulang tentang cara kerja organ tubuh setiap memulai tahap!
  - **Lab Peningkatan Organ:** Kumpulkan Koin Sehat untuk meningkatkan 7 organ hingga Lv. 5 secara permanen.
  - **100 Tahap di 10 Tema Alam + Mode Zen + Tantangan Harian:** Nikmati 10 latar belakang biome unik dengan papan kaca transparan, rintangan alam (batu, batang pohon, pulau mini), serta 3 ukuran papan (Mudah 5×7, Sedang 6×9, Sulit 7×12).
  - **Gratis 15 Menit Setiap Hari + dr. Erta Pass:** Coba semua fitur gratis 15 menit/hari tanpa iklan, atau berlangganan **dr. Erta Pass** (Bulanan / Tahunan) untuk main tanpa batas di NADILOOPA & seluruh aplikasi/game dr. Erta dengan 1 akun.

  *Catatan: NADILOOPA adalah game hiburan. Meter Nadi fiktif dan 330 fakta kesehatan disajikan untuk hiburan & wawasan umum, bukan nasihat atau diagnosis medis.*

---

## 3. Play Console Compliance Checklist
- **Version:** `v3.0.0` (`versionCode = 15`, `package = com.nadiloopa.puzzle`, `minSdk = 24`, `targetSdk = 35`, `arm64-v8a + armeabi-v7a`)
- **Assets Ready in `docs/play_store/`:**
  - `icon_512.png` (512×512 PNG)
  - `feature_graphic_1024x500.png` (1024×500 PNG)
  - `DR_ERTA_PASS_SETUP_GUIDE.md` (Panduan lengkap setup Firebase + RevenueCat + Google Play Subscriptions)
- **Privacy Policy URL:** `https://github.com/ertapriadi-ui/nadiloopa/blob/main/docs/PRIVACY_POLICY.md`
- **Data Safety:** Declare optional **Email address** (Account management / cross-app sync) & **Purchase history** (Subscription verification), encrypted in transit, with in-app **Delete Account** support.
- **Content Rating (IARC):** Declare **"References to Alcohol & Tobacco"** (due to the educational anti-binge-drinking and anti-smoke hazard events) — expected rating **Teen / 12+**.
- **Release AAB Signing (One-Time Setup):**
  1. Generate your private upload keystore locally (keep the file & password safe forever — Google Play requires the same upload key for future updates):
     ```bash
     keytool -genkeypair -v -keystore nadiloopa-upload.keystore -alias nadiloopa -keyalg RSA -keysize 2048 -validity 10000
     base64 -w 0 nadiloopa-upload.keystore > nadiloopa-upload.keystore.b64
     ```
     *(Use the same password for both keystore password and key password.)*
  2. Add 4 GitHub Repository Secrets in **Settings → Secrets and variables → Actions**:
     - `ANDROID_KEYSTORE_BASE64` (contents of `nadiloopa-upload.keystore.b64`)
     - `ANDROID_KEYSTORE_PASSWORD`
     - `ANDROID_KEY_ALIAS` (`nadiloopa`)
     - `ANDROID_KEY_PASSWORD`
  3. Open **GitHub Actions → NADILOOPA Release AAB (Google Play) → Run workflow** to build and download the signed `nadiloopa_release.aab` ready to upload to Google Play Console!
