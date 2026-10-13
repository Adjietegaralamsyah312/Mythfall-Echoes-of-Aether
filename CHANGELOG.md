# CHANGELOG — Mythfall: Echoes of Aether

Hanya capaian terverifikasi di file + `git log`. Rencana tidak dicatat sebagai selesai. Istilah sama dengan `docs/CONTENT_PACKS.md` dan `docs/GAME_DESIGN_DOCUMENT.md`.

## Verifikasi (2026-10-13, sesi DOC-001)

- HEAD `c5a0683`, branch `main`, remote `origin https://github.com/Adjietegaralamsyah312/Mythfall-Echoes-of-Aether`.
- `du -sb`: `Assets` 2.875.305 (termasuk `.import`), `Scenes` 43.227, `Scripts` 111.936, `Data` 12.160, `LICENSES` 3.088, `docs` 13.314; Initial Pack terpasang 3.026.492 B (`Data/Packs/initial.tres`).
- Target distribusi awal 100.000.000 B → **kurang 96.973.508 B (~97 MB)**. APK lokal 0 (`Build/` kosong). Jangan baca target sebagai tercapai.
- APK CI: info delegasi sebelumnya mencatat artifact 30.534.588 byte run 38339269237; run untuk `c5a0683` = 38342337012 — **status run belum diverifikasi ulang di sesi ini, cek di GitHub Actions**. Jangan klaim CI berhasil sebelum terverifikasi.
- Uji perangkat fisik / Editor Android manual: belum dilakukan di sesi ini.

## Riwayat (dari `git log --oneline`, terlama → terbaru)

- `2b97349` — chore: safety checkpoint + Android export preset + build docs (C-001). Preset `Android` (`arm64-v8a` saja, orientasi landscape 4, ID `com.mythfall.echoesofaether`), `docs/ANDROID_BUILD.md`, `docs/ENVIRONMENT.md`, `.gitignore` lindungi `export_presets.cfg`.
- `8d33a76` — ci: android debug APK workflow Godot 4.7.2 (C-002). `.github/workflows/android-debug-apk.yml` (engine pin 4.7.2, template cocok, import headless, export preset `Android`, verifikasi APK >5 MB dan <500 MB).
- `1c34c33` — ci: fix sdkmanager path absolut (C-002 iterasi 1).
- `d3f010e` — ci: ratakan subdir templates tpz (C-002 iterasi 2).
- `aeb0c3a` — fix: hapus `=` dari komentar `export_presets.cfg` agar parser Godot lolos (C-003).
- `c5a0683` — feat: add content pack registry and secure downloader. D1 manifest (`Data/Packs/*.tres`, `PackDef/Registry`) + D2 downloader aman (`PackDownloader`: tolak BUILT_IN/UNAVAILABLE, tolak `file_bytes -1`, wajib sha256, timeout 30 dtk retry 1x, verifikasi SHA-256, tolak ZIP Slip, catat `user://content_packs/installed.json`) + panel + `Tests/D2_PackTest.gd`. 5 paket ekspansi tetap UNAVAILABLE.

## Gameplay terverifikasi di file (Phase B, tanpa klaim rilis)

- Player/kamera/sentuh (B1): `PlayerStats` (speed 180, attack 12), `TouchControls` joystick + tombol, kamera zoom 3 + limit map.
- Combat/loot/progression (B2): `Health/Hitbox/Hurtbox/Projectile`, `Inventory` 20 slot, `Progression` XP `100*level`, 4 item + 4 musuh (`Data/`).
- Quest/NPC (B3): 3 quest Indonesia + Elder Maren/Bram/Sari.
- Region (B4): valley 2560×1440 + crypt 1280×720, entrance/exit, checkpoint, chest, `RegionManager`.
- Save/UI/VFX/Audio (B5): `SaveManager` (`user://mythfall_save.cfg` v1), `GameUI` kode, `VFX` pooled + quality, SFX `.ogg` nyata; musik ambient belum ada.
- Uji headless + soak dilaporkan hijau di `docs/ANDROID_TEST_PLAN.md` (B2/B3/B4/B5 + soak Main 3600 frame 0 error). Bukan pengganti uji perangkat.

## Aset

5 zip Kenney CC0 2.284.476 B, terekstrak 2.427.779 B (`ASSET_MANIFEST.json`); `Assets/` di disk 2.875.305 B (termasuk `.import`). Rincian: `ASSET_CREDITS.md`, `LICENSES/`, `docs/ASSET_PIPELINE.md`.

## Belum selesai (jujur)

- 5 region ekspansi, musik ambient, perbandingan equipment, rilis GitHub Release, uji perangkat fisik, keputusan lisensi kode (lihat `LICENSE`).
- Tahap 100 MB: butuh aset CC0 terverifikasi + integrasi nyata per paket (lihat `CONTENT_PACKS.md` §5). Dilarang dummy/padding/duplikasi (Prioritas D).

## Uncommitted E2+E3 (2026-10-13, JANGAN baca sebagai commit)

- E2 (belum commit): Emberfall Highlands playable lokal (`EmberfallHighlands.tscn`, `ember_wisp`, portal dua arah, `IMPACT_MAP`), 5 dir runtime baru + 5 `LICENSES/`.
- E3 (belum commit): `emberfall.tres` v0.1.0 (318.047 B, 10 contents, tetap UNAVAILABLE-unduh) + `initial.tres` 3.369.507 B union; `Tools/count_content.py` union 3.369.507 B → kurang 96.630.493 B ke 100 MB; `ASSET_MANIFEST.json` 10 paket; `Tests/E3_PackTest.gd`; docs Emberfall playable.

## Uncommitted F2+F3 (2026-10-13, JANGAN baca sebagai commit)

- F2 (belum commit): Luminara Desert playable lokal (`LuminaraDesert.tscn` 9.235 B, `LuminaraDesert.gd` 1.134 B, `luminara_desert.tres`, portal Valley 1350,150 dua arah, 4 encounter, chest 2 shard+1 helm, checkpoint autosave) + lava strip 17.212/floor 6.706 (dekor tanpa damage) + ambient 1.626.352 (Emberfall/crypt; desert tanpa musik) + sand 3.049; `Tests/F2_LuminaraTest.gd`.
- F3 (belum commit): `luminara.tres` v0.1.0 (1.667.496 B, 6 contents, tetap UNAVAILABLE-unduh pola E3) + `initial.tres` 5.042.552 B union; `ASSET_MANIFEST.json` 14 paket (4 baru F1, OGA tanpa file lisensi → URL+CC0); `Tests/F3_PackTest.gd`; docs Luminara playable; `Tools/count_content.py` tanpa ubah (luminara sudah di daftar pack).
