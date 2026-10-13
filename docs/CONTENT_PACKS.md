# CONTENT PACKS — Mythfall: Echoes of Aether (D1)

Sistem manifest paket konten. Unduh/instal/verifikasi = D2 (belum ada).

## 1. Paket (kontrak ID beku untuk D2)

| pack_id | Isi | Status | Ukuran aktual |
|---|---|---|---|
| `initial` | Menu, gameplay awal, Dawnroot Valley + Crypt, UI, efek, audio awal | BUILT_IN | 3.026.492 B terpasang (`du`, 2026-10-13) |
| `emberfall` | Rencana: Emberfall Highlands | UNAVAILABLE | -1 (belum ada) |
| `luminara` | Rencana: Luminara Desert | UNAVAILABLE | -1 (belum ada) |
| `veilwood` | Rencana: Veilwood Forest | UNAVAILABLE | -1 (belum ada) |
| `azure` | Rencana: Azure Shattercoast | UNAVAILABLE | -1 (belum ada) |
| `aether_crown` | Rencana: Aether Crown (endgame) | UNAVAILABLE | -1 (belum ada) |

Manifest: `Data/Packs/*.tres`. Skema: `Scripts/ContentPacks/PackDef.gd`.
Registry baca-manifest: `Scripts/ContentPacks/PackRegistry.gd`
(`load_all/get_pack/list_packs/is_available/is_built_in/installed_size`,
sinyal `pack_list_changed`).

## 2. Region ID (beku)

`dawnroot_valley`, `dawnroot_crypt` (ada) + `emberfall_highlands`,
`luminara_desert`, `veilwood_forest`, `azure_shattercoast`, `aether_crown`
(rencana; merujuk nama plan.md Prioritas A).

## 3. Ukuran aktual vs target (jujur, 2026-10-13)

| Metrik | Byte aktual | Catatan |
|---|---|---|
| Aset Kenney (5 zip) | 2.284.476 | `ASSET_MANIFEST.json` |
| Aset terekstrak (zip) | 2.427.779 | idem |
| `Assets/` di disk | 2.875.305 | termasuk `.import` editor (+447.526) |
| Initial Pack terpasang | 3.026.492 | `du -sb Assets+Scenes+Scripts+Data+LICENSES` |
| Source proyek (tanpa `.git`/`.godot`) | ~3,07 MB | `.git` (~2,7 MB) + `.godot` (~2,6 MB) BUKAN konten |
| APK lokal | 0 (belum ada) | `Build/` kosong; klaim 29 MB sebelumnya TIDAK terbukti di disk |
| Total konten nyata siap main | 3.026.492 | = Initial Pack |
| Target distribusi awal | 100.000.000 | **kurang 96.973.508 B (~97 MB)** |
| Target jangka panjang | 2–3 GB lintas paket | 5 paket ekspansi masih -1 (0 B nyata) |

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
