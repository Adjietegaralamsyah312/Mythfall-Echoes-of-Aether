# CONTENT PACKS — Mythfall: Echoes of Aether (D1)

Sistem manifest paket konten. Unduh/instal/verifikasi = D2 (belum ada).

## 1. Paket (kontrak ID beku untuk D2)

| pack_id | Isi | Status | Ukuran aktual |
|---|---|---|---|
| `initial` | Menu, gameplay awal, Dawnroot Valley + Crypt, UI, efek, audio awal (+ file E2, subset Emberfall di dalam) | BUILT_IN | 3.369.507 B terpasang (`du`, 2026-10-13) |
| `emberfall` | Emberfall Highlands playable lokal (portal dua arah, 5 encounter, chest, checkpoint) — BELUM bisa diunduh | UNAVAILABLE* | 318.047 B terpasang lokal; unduhan -1/URL kosong |
| `luminara` | Rencana: Luminara Desert | UNAVAILABLE | -1 (belum ada) |
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
| Emberfall subset runtime | 318.047 | Caves 32.172 + Urban 18.270 + Foliage 171.275 + RPGExpansion 12.666 + Impacts 70.378 + scene/script/data 13.286 (`du`) |
| Initial Pack terpasang (union) | 3.369.507 | `du -scb Assets+Scenes+Scripts+Data+LICENSES`; sudah termasuk subset Emberfall (tanpa double-count) |
| Total konten nyata siap main | 3.369.507 | = Initial union (`python3 Tools/count_content.py`) |
| Ekspansi siap (Emberfall) | 318.047 | subset di atas; 4 paket lain 0 B |
| `Sources/` staging | 13.188.610 | arsip + extracted E1 — BUKAN konten, jangan hitung |
| Source proyek (tanpa `.git`/`.godot`) | ~3,4 MB | `.git` 2.789.334 + `.godot` 8.023.199 BUKAN konten |
| APK lokal | 0 (belum ada) | `Build/` kosong; klaim 29 MB sebelumnya TIDAK terbukti di disk |
| Target distribusi awal | 100.000.000 | **kurang 96.630.493 B (~96,6 MB)** |
| Target jangka panjang | 2–3 GB lintas paket | 4 paket ekspansi masih -1 (0 B nyata) |

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
- Hosting tersisa: zip per-pack + URL + sha256 server + upload (tanpa karang URL); lalu status AVAILABLE + `file_bytes` nyata. 4 region lain tetap RENCANA (0 B).
