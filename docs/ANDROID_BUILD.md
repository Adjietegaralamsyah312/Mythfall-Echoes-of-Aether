# ANDROID BUILD — Mythfall: Echoes of Aether

Target: APK **debug** untuk pengujian lokal. Engine: **Godot 4.7.x stable**.
Preset: `Android` (lihat `export_presets.cfg` di root proyek).

Konfigurasi preset (kontrak beku untuk CI — jangan ubah sepihak):

- Preset name: `Android`, platform `Android`
- Package ID: `com.mythfall.echoesofaether`
- Export path: `Build/Mythfall-debug.apk`
- Arsitektur: hanya `arm64-v8a=true` (ARM64)
- Orientasi: landscape (`screen/orientation=4`, cermin `project.godot`)
- Signing: debug keystore bawaan editor (tidak ada keystore di repo)

## Prasyarat (Godot Editor Android)

1. Buka proyek (`project.godot`) di Godot Editor Android, tunggu import 0 error.
2. Pastikan **export template 4.7.x** terpasang di editor
   (apabila menu Export meminta template, pasang versi yang cocok
   dengan engine — jangan campur versi).
3. Verifikasi: preset `Android` muncul di dialog Export;
   package ID dan orientasi sesuai daftar di atas.

## Export APK debug (Editor Android)

1. Menu **Project → Export…**
2. Pilih preset **Android** di daftar kiri.
3. Klik **Export Project… →** pilih mode **Debug**.
4. Simpan ke `Build/Mythfall-debug.apk`
   (folder `Build/` sudah ada di repo via `.gitkeep`).
5. Catat ukuran APK aktual — jangan klaim sebelum file benar-benar ada.

## Pasang & uji di perangkat

- Transfer APK via USB/WiFi ke perangkat, atau export langsung
  ke perangkat bila editor mendukung instalasi sekali sentuh.
- Uji minimal (detail penuh: `docs/ANDROID_TEST_PLAN.md`):
  landscape, sentuh, quest, combat, save/load.

## Signing & keamanan

- Build debug memakai debug keystore bawaan — cukup untuk uji lokal.
- **JANGAN** commit `*.keystore`, password, atau token ke repo
  (sudah di-ignore di `.gitignore`). Rilis Play Store ditangani terpisah.

## Keterbatasan Termux (faktual, per cek 2026-10-13)

- CLI lokal `godot 4.7.2.stable.termux --headless --import`:
  **exit 0, 0 error** — validasi proyek bisa jalan headless.
- CLI mendukung flag `--export-debug <preset> <path>`
  (terverifikasi via `godot --headless --help`).
- **Export lokal TIDAK bisa dilakukan**: folder
  `~/.local/share/godot/export_templates/` **ada tapi kosong**
  (template Android tidak terpasang). Template berukuran puluhan MB
  dan **tidak diunduh** tanpa izin eksplisit.
- Konsekuensi: APK debug harus dibuat via Godot Editor Android
  (langkah di atas) atau via GitHub Actions CI (tugas C-002:
  workflow mengunduh engine 4.7.2 + export template yang cocok,
  lalu export preset `Android` yang sama).
