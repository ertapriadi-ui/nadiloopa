# Panduan Setup dr. Erta Pass (Firebase + RevenueCat + Google Play Billing)

Dokumen ini menjelaskan langkah-langkah satu kali (*one-time setup*) agar fitur **15 Menit Gratis/Hari + Langganan Lintas Aplikasi `dr. Erta Pass`** aktif sepenuhnya di Google Play Store dan bisa langsung dipakai ulang di seluruh aplikasi & game **dr. Erta** berikutnya.

---

## Ringkasan Arsitektur
- **Login Lintas Aplikasi:** Firebase Authentication (Email/Password — **Gratis / Spark Plan**).
- **Sinkronisasi Langganan Lintas Aplikasi:** RevenueCat (**Gratis hingga \$2.500 pendapatan/bulan**).
- **Pembayaran Android:** Google Play Billing (`dr_erta_pass_monthly` & `dr_erta_pass_yearly`).
- **Kunci konfigurasi di kode:** Hanya perlu mengisi **2 API Key** di [`data/monetization_config.json`](../../data/monetization_config.json)!

---

## Langkah 1 — Buat Proyek Firebase (Gratis)
1. Buka [Firebase Console](https://console.firebase.google.com/) → klik **Add project** → beri nama `dr-erta-ecosystem`.
2. Di menu kiri, buka **Build → Authentication → Get started**.
3. Di tab **Sign-in method**, aktifkan **Email/Password** → klik **Save**.
4. Buka **Project Settings (ikon roda gigi) → General** → salin **Web API Key** (contoh: `AIzaSy...`).
5. Tempelkan nilai tersebut ke field `"firebase_web_api_key"` di `data/monetization_config.json`.

---

## Langkah 2 — Buat Produk Langganan di Google Play Console
1. Buka [Google Play Console](https://play.google.com/console) → pilih aplikasi **NADILOOPA** (`com.nadiloopa.puzzle`).
2. Buka menu **Monetize → Products → Subscriptions** → klik **Create subscription** dan buat 2 produk dengan **Product ID persis berikut**:
   - **`dr_erta_pass_monthly`**
     - Base plan ID: `monthly`
     - Periode tagihan: **1 Month** (misal Rp 29.000/bulan atau \$2.99/mo)
   - **`dr_erta_pass_yearly`**
     - Base plan ID: `yearly`
     - Periode tagihan: **1 Year** (misal Rp 199.000/tahun atau \$19.99/yr — Hemat ~44%)
3. Aktifkan kedua base plan tersebut.

---

## Langkah 3 — Hubungkan RevenueCat (Lintas Aplikasi dr. Erta)
1. Daftar gratis di [RevenueCat](https://www.revenuecat.com/) → buat Project bernama **`dr. Erta Ecosystem`**.
2. Di dalam project tersebut, tambahkan aplikasi Android **`NADILOOPA`** (`com.nadiloopa.puzzle`) dan hubungkan *Google Play Service Account JSON* sesuai panduan resmi RevenueCat.
3. Buka **Product catalog → Entitlements** → klik **New** → buat Entitlement dengan identifier persis:
   - **`dr_erta_pass`**
4. Buka **Product catalog → Products** → tambahkan `dr_erta_pass_monthly` dan `dr_erta_pass_yearly`, lalu kaitkan (*Attach*) keduanya ke entitlement **`dr_erta_pass`**.
5. Buka **Project Settings → API keys** → salin **Public API Key (Google Play)** (diawali `goog_...`).
6. Tempelkan ke field `"revenuecat_google_public_api_key"` di `data/monetization_config.json`.

> **Untuk Aplikasi & Game dr. Erta Berikutnya:**
> Anda cukup memakai **Firebase Project yang sama** dan **RevenueCat Project + Entitlement `dr_erta_pass` yang sama**! Saat pengguna login dengan email yang sama di aplikasi dr. Erta lainnya, status `dr_erta_pass` langsung otomatis aktif tanpa perlu bayar lagi.

---

## Langkah 4 — Data Safety Form di Google Play Console (v3.0.0)
Saat mengisi formulir **Data Safety** di Play Console untuk v3.0.0:
- **Does your app collect or share any of the required user data types?** → **Yes**
- **Data collected:**
  - *Personal info → Email address* (Optional, for App functionality & Account management)
  - *Financial info → Purchase history* (For App functionality — subscription verification)
  - *App info and performance / Device or other IDs* → No (unless added later)
- **Is all of the user data collected by your app encrypted in transit?** → **Yes** (HTTPS TLS 1.2+)
- **Do you provide a way for users to request that their data is deleted?** → **Yes** (In-app **Delete Account** button + Privacy Policy URL: `https://github.com/ertapriadi-ui/nadiloopa/blob/main/docs/PRIVACY_POLICY.md`)
