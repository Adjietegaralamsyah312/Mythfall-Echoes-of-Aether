# CONTENT PACKS — Mythfall: Echoes of Aether (D1)

Sistem manifest paket konten. Unduh/instal/verifikasi = D2 (belum ada).

## 1. Paket (kontrak ID beku untuk D2)

| pack_id | Isi | Status | Ukuran aktual |
|---|---|---|---|
| `initial` | Menu, gameplay awal, Dawnroot Valley + Crypt, UI, efek, audio awal (+ file E2/F2, subset Emberfall+Luminara di dalam) | BUILT_IN | 5.042.552 B terpasang (`du`, 2026-10-13) |
| `emberfall` | Emberfall Highlands playable lokal (portal dua arah, 5 encounter, chest, checkpoint) — BELUM bisa diunduh | UNAVAILABLE* | 318.047 B terpasang lokal; unduhan -1/URL kosong |
| `luminara` | Luminara Desert playable lokal (portal dua arah, 4 encounter, chest, checkpoint) — BELUM bisa diunduh | UNAVAILABLE* | 1.667.496 B terpasang lokal; unduhan -1/URL kosong |
| `veilwood` | Rencana: Veilwood Forest | UNAVAILABLE | -1 (belum ada) |
| `azure` | Rencana: Azure Shattercoast | UNAVAILABLE | -1 (belum ada) |
| `aether_crown` | Rencana: Aether Crown (endgame) | UNAVAILABLE | -1 (belum ada) |

\*Status jujur E3: `emberfall` tetap UNAVAILABLE untuk unduh (tanpa hosting: `download_url ""`, `file_bytes -1`, `sha256 ""` — jangan karang URL), tapi konten lokal terpasang + playable offline (lihat §8). `is_available("emberfall")==false` dipertahankan agar D2/panel tetap tolak unduh jujur.

Manifest: `Data/Packs/*.tres`. Skema: `Scripts/ContentPacks/PackDef.gd`.
Registry baca-manifest: `Scripts/ContentPacks/PackRegistry.gd`
(`load_all/get_pack/list_packs/is_available/is_built_in/installed_size`,
sinyal `pack_list_changed`).

## 2. Region ID (beku)

`dawnroot_valley`, `dawnroot_crypt` (ada) + `emberfall_highlands`,
`luminara_desert`, `veilwood_forest`, `azure_shattercoast`, `aether_crown`
(rencana; merujuk nama plan.md Prioritas A).

## 3. Ukuran aktual vs target (jujur, 2026-10-13, E3)

| Metrik | Byte aktual | Catatan |
|---|---|---|
| Aset Kenney zip (10 paket) | 6.026.122 | `ASSET_MANIFEST.json` (5 lama 2.284.476 + 5 baru 3.741.646) |
| Aset F1 file CC0 (4 file) | 1.666.321 | floor 6.706 + Lava.zip 30.214 + ambient 1.626.352 + sand 3.049 (sumber; runtime 1.656.662 + scene/script/data 10.834) |
| Emberfall subset runtime | 329.853 | 11 contents (Caves/Urban/Foliage/Scorched/RPGExpansion/Impacts + scene/script/data; `count_content.py` SHA-256) |
| Luminara subset runtime | 1.672.604 | 7 contents (Emberfall/Luminara/DesertDebris/Ambience + scene/script/data; `count_content.py` SHA-256) |
| BULK-001 musik + visual | 122.533.733 | MusicLibrary 16 trek 122.521.864 + Scorched/DesertDebris 11.869 (dgn `.import`; subset MP3-duplikat ditolak) |
| Initial Pack terpasang (union) | 127.584.207 | `Tools/count_content.py` dedup SHA-256; sudah termasuk subset Emberfall+Luminara+musik (tanpa double-count) |
| Total konten nyata siap main | 127.584.207 | = Initial union (`python3 Tools/count_content.py`); LEBIH target 100 MB 27.584.207 B |
| Ekspansi siap (Emberfall+Luminara) | 2.002.424 | 329.853 + 1.672.604 (subset di atas; 3 paket lain 0 B) |
| `Sources/` staging | 13.188.610 | arsip + extracted E1 — BUKAN konten, jangan hitung |
| Source proyek (tanpa `.git`/`.godot`) | ~5,0 MB | `.git` 2.789.334 + `.godot` 8.023.199 BUKAN konten |
| APK lokal | 0 (belum ada) | `Build/` kosong; klaim 29 MB sebelumnya TIDAK terbukti di disk |
| Target distribusi awal | 100.000.000 | **kurang 94.957.448 B (~95,0 MB)** |
| Target jangka panjang | 2–3 GB lintas paket | 3 paket ekspansi masih -1 (0 B nyata) |

Toleransi: angka manifest bisa meleset ±16 KB karena file `.import`
hasil editor dan manifest itu sendiri — bukan dummy, jelaskan bila ditanya.

## 4. Strategi distribusi (plan.md Prioritas C)

- JANGAN unduh total 2–3 GB otomatis. Pengguna memilih paket per region.
- Main offline penuh untuk paket terpasang (Dawnroot = `initial` BUILT_IN).
- Status paket jujur: tanpa URL + hash nyata = UNAVAILABLE, bukan "tersedia".

## 5. Tahapan ekspansi realistis

1. Emberfall dulu (satu region nyata, bukan 5 scene kosong).
2. Tiap paket: aset CC0 terverifikasi → integrasi ke scene/encounter/quest
   → manifest (ukuran `du` + sha256 nyata) → status AVAILABLE + URL nyata.
3. D2 mengisi: download manager, verifikasi hash, instal ke direktori data
   aplikasi, penolakan path traversal/ZIP Slip.

## 6. Larangan (plan.md Prioritas D)

DILARANG: file dummy/padding, duplikasi aset demi ukuran, fake extension,
menghitung `.git`/`.godot`/arsip tak terpakai sebagai konten, dan aset
berlisensi tak jelas. Bila target tak tercapai: laporkan kekurangan, jangan
karang keberhasilan.

## 7. Pemakaian D2 (download manager, 2026-10-13)

Alur: pengguna memilih paket manual di panel (tak ada unduh otomatis) →
`PackDownloader.start(pack_id)` menolak jujur bila BUILT_IN/UNAVAILABLE/URL
kosong → tolak bila `file_bytes` -1 (Godot tak punya API ruang kosong
portabel; ukuran tak diketahui = jangan unduh) → tolak bila `sha256` kosong
(jangan instal tanpa verifikasi) → HTTP (`HTTPRequest`, timeout 30 dtk,
retry 1x, bisa batal) dengan sinyal
`download_progress/download_finished/download_failed` (Indonesia) → verifikasi
SHA-256 (`FileAccess.get_sha256`; mismatch = hapus file + gagal) → ekstrak
aman (`ZIPReader`; pra-pindai: satu entri `..`/absolute/drive = tolak seluruh
arsip) ke `user://content_packs/<pack_id>/` → catat
`user://content_packs/installed.json` via `InstalledRegistry`
(`mark_installed/remove/list_installed`; corrupt = reset aman + alasan).

Panel: `Scenes/UI/ContentPacksPanel.tscn` (+ script, dibangun via kode ikut
pola `GameUI`); daftar 6 paket + ukuran butuh/terpasang + tombol Unduh yang
disable + alasan untuk BUILT_IN/UNAVAILABLE; progress bar + pesan jujur;
tombol Kembali; dibuka dari tombol "Paket Konten" di Settings (MainMenu +
GameUI). Uji: `godot --headless --path . -s Tests/D2_PackTest.gd`
(zip/sha/registry uji memakai `user://d2_tmp_*` saat jalan — bukan `/tmp`
yang tak ada di Android — dan tak di-commit).

Batas jujur: belum ada server/URL/hash paket nyata — 5 paket ekspansi tetap
UNAVAILABLE sampai ada aset CC0 terverifikasi + manifest nyata (lihat §5).

## 8. Emberfall E3 — playable lokal, belum hosting (2026-10-13)

- Scene: `Scenes/World/EmberfallHighlands.tscn` (1920×1080, basalt Caves + pos Urban + foliage hangus + lava Polygon2D pulse + pilar/reruntuhan + outpost + checkpoint + ExitPortal + Bounds) + `Scenes/Enemies/EmberWisp.tscn` (`ember_wisp` HP45 dmg11 ranged).
- Region: `Data/Regions/emberfall_highlands.tres` (`spawn/checkpoint 960,900`); portal dua arah: Valley `EmberPortal (1000,150)` → Emberfall checkpoint; Emberfall `ExitPortal (960,1000)` → Valley.
- Audio: `AudioManager.IMPACT_MAP` (footstep_ember/hit_metal/mine/punch) + footstep loop di `Main._process` khusus Emberfall.
- Manifest: `Data/Packs/emberfall.tres` v0.1.0, `installed_bytes 318047`, `contents` 10 path runtime E2, `license_note` CC0; `download_url ""`, `file_bytes -1`, `sha256 ""`, status tetap UNAVAILABLE (unduh ditolak jujur; main offline tetap jalan).
- Hitung: `python3 Tools/count_content.py` → union 3.369.507 B, selisih 96.630.493 B ke 100 MB. `Sources/` 13.188.610 B staging tidak dihitung.
- Hosting tersisa: zip per-pack + URL + sha256 server + upload (tanpa karang URL); lalu status AVAILABLE + `file_bytes` nyata. 3 region lain tetap RENCANA (0 B).

## 9. Luminara F3 — playable lokal, belum hosting (2026-10-13)

- Scene: `Scenes/World/LuminaraDesert.tscn` (1920×1080, sand desert_sand CC0 + paver/batu hangat existing via modulate + reruntuhan + Gerbang Terbenam + oasis + checkpoint + ExitPortal + Bounds) + script `Scripts/World/LuminaraDesert.gd` (pasif, pola B4).
- Region: `Data/Regions/luminara_desert.tres` (`spawn/checkpoint 960,900`); portal dua arah: Valley `LuminaraPortal (1350,150)` → Luminara checkpoint; Luminara `ExitPortal (960,1000)` → Valley `(640,300)`.
- Aset F1: lava strip 17.212 + floor 6.706 (Emberfall dir, dipakai Emberfall anim/dekor) + ambient 1.626.352 (Emberfall/crypt; desert tanpa musik TERBUKA jujur) + sand 3.049 (Luminara). OGA tanpa file lisensi → URL+CC0 di manifest, tanpa karang file.
- Manifest: `Data/Packs/luminara.tres` v0.1.0, `installed_bytes 1667496`, `contents` 6 path runtime F2, `license_note` CC0; `download_url ""`, `file_bytes -1`, `sha256 ""`, status tetap UNAVAILABLE (unduh ditolak jujur; main offline tetap jalan — pola E3).
- Hitung: `python3 Tools/count_content.py` → union 5.042.552 B, selisih 94.957.448 B ke 100 MB. 32px-zip DITOLAK + Foozle GAGAL: hanya SOURCING_LOG §6, TIDAK masuk manifest.

## 10. BULK-001 HundredMB — musik + visual, target tercapai (2026-10-13)

- Sumber (resolve dari HTML resmi, verifikasi HTTP+ukuran+`unzip -t`+sha256+lisensi per item; CC0 semua): `music-loops-0` drakzlin (5 zip, 101.521.916 B staging) → subset 8 WAV; `fantasy-song-pack-volume-1` troubadour (8 MP3, 27.449.343 B) → semua dipakai; `tiny-rpg-forest` ansimuz (zip 5.788.353, public domain) → subset 4 PNG. MP3-duplikat + PSD/Demo/sound + Kenney platformer (side-view, tak cocok top-down) + GameLoops-cadangan DITOLAK-inklusi (staging/bukti saja).
- Sistem SATU: `MusicCatalog.gd` (16 trek + AUTO_BGM menu/valley/luminara) + perluasan `AudioManager` (`play_music` lazy-load loop + anti-overlap dua arah) + panel Musik `GameUI` (16 tombol + Stop) + BGM menu `MainMenu` + auto-BGM `Main._after_load_region` (ember/crypt tetap ambient). Tanpa ubah gameplay inti.
- Visual: `Scorched/` (pohon hangus + monolit → Emberfall) + `DesertDebris/` (kayu + batu → Luminara); Dawnroot tak tersentuh.
- Manifest: `ASSET_MANIFEST.json` 21 item (7 baru BULK); `initial.tres` 127.584.207 B union; `emberfall.tres` 329.853 B (11 contents); `luminara.tres` 1.672.604 B (7 contents); pack tetap UNAVAILABLE (tanpa hosting, tanpa karang URL).
- Hitung: `python3 Tools/count_content.py` (dedup SHA-256) → union 127.584.207 B, LEBIH target 100 MB 27.584.207 B; `DEDUP_SHA256_SKIPPED` 2.058.925 B bukti dedup. LOOP BERHENTI (buffer 125 MB tercapai).
- Uji: `Tests/BULK001_MusicTest.gd` (katalog+play+overlap+manifest+gate+yatim+dekor+UI) + F3/E3/D2 konstanta disinkron; B2/B3/B4/B5/F2 hijau. `--import` exit 0. APK aktual 0 lokal (jujur).
