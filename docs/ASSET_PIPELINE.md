# ASSET PIPELINE — Phase A + E1/E2 (Emberfall)

Prosedur unduh 5 paket Kenney (berhasil semua, 2026-10-13):

1. Buka halaman resmi paket (`https://kenney.nl/assets/<slug>`).
2. Verifikasi tulisan "CC0 licensed" di halaman.
3. Resolve link unduhan dari HTML halaman (tombol Download → modal
   `#inline-download` → `href` `.zip` di `kenney.nl/media/...`).
   URL zip TIDAK dikarang — diekstrak dari halaman via `grep`.
4. Unduh via `curl -sL`, verifikasi integritas `unzip -t` (5/5 OK).
5. Ekstrak ke `Assets/...`, salin `License.txt` asli ke `LICENSES/`.
6. Catat ukuran + sha256 di `ASSET_MANIFEST.json`.

Unduhan manual (jika pipeline diulang): buka tiap URL di
`ASSET_CREDITS.md`, klik Download → "Continue without donating".

Catatan: file `.url` bawaan Kenney (Donate/Facebook/Visit) ikut
terekstrak apa adanya; boleh dihapus saat bersih-bersih Phase B.
Impor `.import` Godot dibuat saat proyek dibuka di editor.

## E1→E2: Sources → runtime (Emberfall, 2026-10-13)

`Sources/` = staging ignore-git (zip + extracted + `SOURCING_LOG.md`),
BUKAN konten. E2 hanya salin subset hemat ke runtime (jangan semua isi):

- `Sources/roguelike-caves-dungeons/extracted/Spritesheet/roguelikeDungeon_transparent.png` → `Assets/Environment/Caves/` (+ `License.txt` → `LICENSES/kenney_roguelike-caves-dungeons_LICENSE.txt`)
- `Sources/rpg-urban-pack/extracted/Tilemap/tilemap_packed.png` → `Assets/Environment/Urban/` (+ License)
- `Sources/foliage-pack/extracted/Spritesheet/foliagePack_default.png` + `.xml` → `Assets/Environment/Foliage/` (default saja, bukan retina)
- `Sources/ui-pack-rpg-expansion/extracted/PNG/bar*.png` + `button*.png` → `Assets/UI/RPGExpansion/`
- `Sources/impact-sounds/extracted/Audio/footstep_*` + `impactMining_*` + `impactMetal_heavy_*` + `impactPunch_*` → `Assets/Audio/Impacts/`
- rpg-base DITOLAK (duplikat), polyhaven DITOLAK (visual 3D), roguelike-rpg-pack DILEWATI (sudah ada) — bukti di `Sources/SOURCING_LOG.md` §1.

Hitung ulang via `python3 Tools/count_content.py` (union anti-double-count; toleransi ±16 KB untuk `.import`/manifest itu sendiri).

## F1→F2: Sources → runtime (Luminara + lava/ambient, 2026-10-13)

`Sources/` = staging ignore-git, BUKAN konten. F2 hanya salin subset hemat ke runtime:

- `Sources/floor-is-lava/floor_is_lava.png` → `Assets/Environment/Emberfall/` (crust static; OGA CC0 Kipperfalcon, tanpa file lisensi — URL+CC0 di manifest)
- `Sources/lpc-lava-16x16-45f/lava_spr_strip45.png` → `Assets/Environment/Emberfall/` (strip 45f utama; LPC CC0 davesch; varian 32px DITOLAK — hanya SOURCING_LOG §6)
- `Sources/dungeon-ambience-loop/dungeon_ambient_1.ogg` → `Assets/Audio/Ambience/` (loop via flag AudioStreamOgg; OGA CC0 JaggedStone)
- `Sources/desert-sand-16x16/voda_pesok_trava_revision_2.png` → `Assets/Environment/Luminara/desert_sand.png` (ganti nama, byte+sha identik; OGA CC0 Demetrius)
- foozle GAGAL (purchase JS + 404) → TIDAK ADA runtime; CC0 tercatat bila nanti unduh manual via browser.

Hitung: `luminara.tres` 6 contents = 1.667.496 B; `initial.tres` union baru 5.042.552 B.
