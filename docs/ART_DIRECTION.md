# ART_DIRECTION — Mythfall: Echoes of Aether

Gaya: **HD-2D Pixel-Modern Mewah** (pixel art konsisten + top-down, lihat `plan.md` seksi 3 dan `docs/GAME_DESIGN_DOCUMENT.md`).

> Aturan: bagian **TERAPKAN** = terbukti di file. Bagian **ASPIRASI** = belum ada di file. Jangan campur.

Dokumen terkait: `GAME_DESIGN_DOCUMENT.md`, `WORLD_LORE.md`, `WORLD_MAP.md`, `CONTENT_PACKS.md`, `ASSET_CREDITS.md`, `ASSET_MANIFEST.json`.

## 1. Palet aktual (dari file)

| Pakai | Nilai di file | Lokasi |
|---|---|---|
| BG / clear | `Color(0.043, 0.055, 0.078)` (~#0B0E14) | `project.godot` `boot_splash/bg_color` + `default_clear_color`, `Scenes/Boot/Boot.tscn`, `Scenes/MainMenu/MainMenu.tscn` |
| Font terang | `Color(0.91, 0.86, 0.76)` | `Boot.tscn`, `MainMenu.tscn` |
| Hutan valley | `Color(0.07, 0.12, 0.08)` | `DawnrootValley.tscn` `GroundForest` 2560×1440 |
| Desa valley | `Color(0.13, 0.12, 0.09)` | `DawnrootValley.tscn` `GroundVillage` (y 840–1440) |
| Jalan valley | `Color(0.16, 0.14, 0.10)` | `DawnrootValley.tscn` `GroundPath` (x 600–680) |
| Crypt gelap | `Color(0.06, 0.06, 0.09)` | `DawnrootCrypt.tscn` `GroundDark` 1280×720 |
| Chest | base `(0.5, 0.35, 0.2)`, lid `(0.85, 0.65, 0.25)`; terbuka `(0.32, 0.24, 0.16)` / `(0.45, 0.45, 0.48)` | `Chest.tscn`, `Scripts/World/Chest.gd` |
| Hit flash | `(1.0, 0.45, 0.45)` | `Scripts/Player/Player.gd`, `Scripts/Enemies/EnemyBase.gd` |
| VFX hit / mati | `(1.0, 0.85, 0.4)` / `(0.7, 0.9, 1.0)` | `Scripts/UI/VFX.gd` |
| Checkpoint / exit | ring `(0.4, 0.85, 0.6, 0.5)`, gerbang `(0.5, 0.4, 0.7, 0.8)` | `DawnrootCrypt.tscn` |
| Overlay UI | `(0.04, 0.06, 0.09, 0.85)` + garis `(1,1,1,0.3)` | `Scripts/UI/GameUI.gd` |
| Sentuh highlight | `(0.75, 0.95, 1.0)` | `Scripts/UI/TouchControls.gd` |

Maksimal 1 BG primer + 1 BG sekunder per area + 1 aksen dipakai konsisten. Jangan tambah gradient/shadow di luar daftar ini tanpa revisi dokumen.

## 2. Pixel-perfect — TERAPKAN

- Semua `Sprite2D` valley/crypt/player/NPC memakai `texture_filter = 1` (nearest). Terbukti di `Player.tscn`, `ElderMaren.tscn`, `Villager.tscn`, seluruh node `DawnrootValley.tscn` / `DawnrootCrypt.tscn`.
- Renderer `gl_compatibility` (`project.godot`). Viewport 1280×720, stretch `canvas_items`, aspect `expand`.
- Skala sprite kelipatan bulat: rumah/gate/crate 3x, pohon/pine/reruntuhan 4x, pilar crypt 3×6. Variasi hanya via `flip_h`, bukan rescale bebas.

## 3. Sprite Kenney yang dipakai — TERAPKAN

Sumber + lisensi: `ASSET_CREDITS.md` + `LICENSES/` (5 paket CC0 Kenney). Detail ukuran: `ASSET_MANIFEST.json`.

- Player: `Assets/Characters/Roguelike/Spritesheet/roguelikeChar_transparent.png` region `Rect2(17, 102, 16, 16)` (`Player.tscn`).
- Elder Maren: spritesheet sama region `Rect2(34, 34, 16, 16)` (`ElderMaren.tscn`).
- Bram: spritesheet sama region `Rect2(68, 34, 16, 16)` (`Villager.tscn`). Sari memakai ulang scene `Villager.tscn` dengan override `npc_id`/`display_name`/`idle_lines` di `DawnrootValley.tscn`.
- Valley: `Assets/Environment/TinyTown/Tilemap/tilemap_packed.png` — rumah `(0,32,80,48)`, `(80,32,64,48)`, `(128,32,64,48)`, gerbang `(0,96,80,64)`; `Assets/Environment/RoguelikeRPG/Spritesheet/roguelikeSheet_transparent.png` — pohon `(221,153)`, `(238,153)`, `(255,153)`, pine `(221,170)`, `(238,170)`, semak `(323,153)`, hedge `(289,170)`, batu `(374,306)`, `(408,306)`, `(374,340)`, paver `(272,238)` dkk, crate `(221,119)`, `(238,119)`.
- Crypt: sheet sama — lantai `(408,238)`, `(425,238)`, obor `(272,119)`, `(289,119)`, pilar `(374,340)`.
- `Sample1.png` / `Sample.png` dicatat di manifest sebagai placeholder Phase A; scene valley/crypt saat ini memakai AtlasTexture di atas, bukan Sample.
- **Belum di-wire visual:** `Assets/UI/FantasyBorders/` (UI premium masih StyleBoxFlat kode), `Assets/Audio/RPG/` hanya untuk SFX (lihat §6).

## 4. Pencahayaan — TERAPKAN vs ASPIRASI

- TERAPKAN: tanpa `Light2D`/`CanvasModulate`/shader. Kedalaman dari ColorRect lapis + `modulate` flash 0.12 dtk + `Polygon2D` gerbang/cincin + damage number `Label` + `z_index = 50`.
- ASPIRASI (belum ada): dynamic 2D lighting, bayangan, kabut, color grading, Y-sort/occlusion. Jangan klaim sudah ada.

## 5. UI — TERAPKAN

- Dibangun via kode ikut pola `GameUI`: `PanelContainer` tengah (questlog 700×440, dialog 800×190 bawah-tengah, pause 420×430), HUD `ProgressBar` HP/Stamina + `VersionLabel` (`Main.tscn`), font default Godot (belum ada font custom).
- `TouchControls.tscn`: `Button` biasa + `StyleBoxFlat` (`bg (1,1,1,0.12)`, border `(1,1,1,0.35)`), bukan `TouchScreenButton`/tekstur.
- `ContentPacksPanel.tscn`: daftar 6 paket + progress bar + tombol disable beralasan.

## 6. Animasi — TERAPKAN

- Single-sprite + `flip_h` (`Player.gd`: `flip_h = facing.x < -0.1`; `NPC.gd` `face()`). Tanpa `AnimatedSprite2D`/frame jalan — sesuai larangan plan: jangan gabung part acak jadi animasi palsu.
- Combat: flash merah, knockback, fade mati, `GPUParticles2D` pooled (6 hit + 4 die, `amount` 8 Balanced / 14 High / 0 Low via `VFX.set_quality`), damage number `Tween` 0.6 dtk.
- Chest: ganti warna base/lid saat dibuka (bukan animasi frame). `LootPickup`: warna permata per tipe + `bob` kode.
- SFX nyata dari file `.ogg` Kenney (`Scripts/UI/AudioManager.gd` `AUDIO_MAP`: swing `drawKnife1`, hit `knifeSlice`, pickup `handleCoins`, dsb). Musik ambient **belum ada** — `Preview.ogg` hanya demo, bukan loop (lihat GDD).

## 7. Konsistensi

- Collision sesuai bentuk gameplay; dekoratif tidak menghalangi (StaticBody hanya rumah/bounds; pohon/semak/obor Sprite tanpa collision). Dinding valley `2592×32` / `32×1472`, crypt `1312×32` / `32×752`.
- Partikel selektif; kualitas Low matikan partikel (`VFX.quality`).
- Perlu aset ekspansi nyata (bukan duplikat): tileset vulkanik, gurun, hutan kabut, pantai, istana/aether + loop ambient CC0 — lihat `CONTENT_PACKS.md` §5 dan `CHANGELOG.md`.
