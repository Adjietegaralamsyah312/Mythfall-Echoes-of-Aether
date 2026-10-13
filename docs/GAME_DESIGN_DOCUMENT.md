# GAME DESIGN DOCUMENT — Mythfall: Echoes of Aether

Status baca: `project.godot`, `Scenes/`+`Scripts/`, `Data/`, `docs/WORLD_MAP.md`, `docs/WORLD_LORE.md`, `docs/ART_DIRECTION.md`, `docs/CONTENT_PACKS.md`. Bahasa quest/dialog: Indonesia.

> Label: **[TERAPKAN]** = ada di file. **[PLANNED]** / **[NOT IMPLEMENTED]** = belum ada. Jangan catat rencana sebagai selesai.

## 1. Identitas & genre

- **[TERAPKAN]** Single-player open-world Action RPG, Android landscape-only, Godot 4 + GDScript, renderer `gl_compatibility`. App ID `com.mythfall.echoesofaether`, versi `0.5.0` / `v0.5.0-b5` (`export_presets.cfg`, `project.godot`, `Scripts/World/Main.gd`). Main scene `res://Scenes/Boot/Boot.tscn`. Lihat `docs/ENVIRONMENT.md`, `docs/ANDROID_BUILD.md`.

## 2. Core loop — [TERAPKAN]

Bicara Elder Maren → quest `dawnroot_intro` (talk) → `dawnroot_wilds` (bunuh 3 slime + kumpul 2 shard) → `dawnroot_sealed_dungeon` (masuk crypt + kalahkan elite) → reward XP/item → level up (`attack_bonus`) → checkpoint/respawn → save manual/autosave. Detail nama/dialog: `WORLD_LORE.md`. Peta/koordinat: `WORLD_MAP.md`.

## 3. Kontrol — [TERAPKAN]

Keyboard+joypad (`project.godot` `[input]`): gerak WASD/arrows (`move_*`), serang J / klik kiri / joypad-0 (`attack`), dodge Spasi / joypad-1, skill E / joypad-2, interact F / joypad-3, pause P/Esc / joypad-6 (+ `ui_cancel` untuk kembali).
Sentuh (`Scenes/UI/TouchControls.tscn`, `TouchControls.gd`): joystick kiri (radius 100, deadzone 0.2, sensitivitas 0.5–1.5) + tombol Attack/Dodge/Skill/Interact/Pause, multitouch (gerak + serang bersamaan), auto-tampil saat `InputEventScreenTouch`, tombol toggle manual. Keyboard tetap jalan untuk uji editor.

## 4. Combat — [TERAPKAN]

- Player (`PlayerStats.gd`, `Player.gd`): `max_hp 100`, `max_stamina 100`, `speed 180`, `dodge_multiplier 2.2`, `dodge_time 0.22`, `dodge_iframes 0.35`, `dodge_cost 20`, `stamina_regen 15`, `attack_damage 12`, `attack_cooldown 0.45`, `attack_range 48`. Gerak 8-arah (`ACCEL 1200`, `FRICTION 1400`), dodge ke arah facing/wish, `take_damage` hormati iframes, mati → `died` → respawn di checkpoint.
- Sistem: `Health`/`Hitbox`/`Hurtbox` team player vs enemy, `Projectile` (wisp `projectile_speed 260`), `EnemyBase` aggro→kejar→windup→serang→cooldown + jaga jarak bila `keeps_distance`, flash + fade + `VFX` + damage number + SFX nyata (`AudioManager.AUDIO_MAP`).
- **[PLANNED]** Perbandingan equipment: `rusty_sword` (`damage_bonus +3`) dan `guard_helm` (armor) bertulis "saat equipment jadi (B5)" di `Data/Items/*.tres` — belum ada layar banding/stat terpasang.

## 5. Progression — [TERAPKAN]

- `Progression.gd`: `xp_needed = 100 * level`, `attack_bonus = (level-1) * 2`, sinyal `xp_changed`/`leveled_up` (Main: heal + bonus).
- Reward nyata: intro `20 XP + 1 health_potion`, wilds `60 XP + 1 rusty_sword`, sealed `120 XP + 1 guard_helm` (`Data/Quests/*.tres`).
- Item nyata (`Data/Items/`): `health_potion` consumable `heal 30` stack 10 ("Efek pakai di B5"), `rusty_sword` weapon stack 1, `guard_helm` armor stack 1, `aether_shard` currency stack 99.
- `Inventory.gd`: kapasitas 20 slot, satu tumpuk per `item_id`, penuh = kembalikan sisa + `changed`.
- Chest sekali-ambil: valley `(1000,720)` = 2 shard + 1 potion; crypt `(640,110)` = 1 helm + 1 sword (`DawnrootValley.tscn`, `DawnrootCrypt.tscn`, `Chest.gd`).

## 6. Musuh — [TERAPKAN] (angka dari `Data/Enemies/*.tres`)

| ID | Nama | HP | Dmg | Speed | Aggro | Range | CD / windup | XP | Khusus + loot |
|---|---|---|---|---|---|---|---|---|---|
| `slime` | Slime | 30 | 6 | 55 | 180 | 26 | 1.4 / 0.4 | 12 | potion 0.35, shard 0.15 |
| `skeleton` | Skeleton | 55 | 11 | 75 | 220 | 28 | 1.1 / 0.55 | 25 | potion 0.25, sword 0.12, shard 0.2 |
| `wisp` | Aether Wisp | 35 | 8 | 130 | 280 | 220 | 1.6 / 0.5 | 30 | ranged, `keeps_distance`, proj 260; shard 0.5, potion 0.2 |
| `elite_dawnroot` | Elite Dawnroot Guardian | 110 | 22 | 80 | 260 | 30 | 1.0 / 0.55 | 80 | sword 0.5, helm 0.35, shard 0.8, potion 0.5 |
| `ember_wisp` | Ember Wisp | 45 | 11 | 140 | 300 | 220 | 1.6 / 0.5 | 38 | ranged, `keeps_distance`, proj 280; shard 0.6, potion 0.25 |

Scene: `Scenes/Enemies/Slime|Skeleton|Wisp|EliteDawnroot.tscn`. Perilaku: `EnemyBase.gd` + `Slime/Skeleton/Wisp.gd`.

## 7. UI — [TERAPKAN]

- `MainMenu.tscn` + `MainMenu.gd`: New Game (navigasi nyata), Continue (disable + status jujur bila tak ada save), Settings (Master/Musik/SFX + quality + sensitivitas, tersimpan), Credits (CC0 Kenney + catatan musik belum ada), Quit, tombol "Paket Konten".
- `GameUI.gd` (dibangun via kode): HUD HP/Stamina/Lv + tracker 1 quest + tombol minimize, Quest Log (Tersedia/Aktif/Selesai + kosong jujur), DialoguePanel (nama + Lanjut/Tutup, sentuh + keyboard), pause, settings, minimap kode (`draw_circle`/`draw_arc`).
- `ContentPacksPanel`: 6 paket + ukuran butuh/terpasang + Unduh disable beralasan + progress + Kembali. Lihat `CONTENT_PACKS.md`.

## 8. Region — [TERAPKAN 3 / PLANNED 4]

Playable: `dawnroot_valley` (2560×1440) + `dawnroot_crypt` (1280×720, `dungeon_id dawnroot_crypt`) + `emberfall_highlands` (1920×1080, playable lokal E2; portal dua arah Valley↔Emberfall; quest Emberfall masih **[PLANNED]**). **[PLANNED]** `luminara_desert`, `veilwood_forest`, `azure_shattercoast`, `aether_crown` — hanya `region_ids` di `Data/Packs/*.tres`, status UNAVAILABLE `-1`, tanpa scene. Penuh: `WORLD_MAP.md`.

## 9. Save — [TERAPKAN]

`SaveManager.gd`: `user://mythfall_save.cfg`, `SAVE_VERSION 1`, `ConfigFile` seksi player/quest/region/settings/meta, save manual + autosave saat `checkpoint_reached`, load validasi versi + `pos` + fallback `{}` + `load_failed` beralasan, `clear`/`has_save`. Tanpa slot/cloud.

## 10. Audio — [TERAPKAN SFX / NOT IMPLEMENTED musik]

SFX dari `.ogg` nyata (`AUDIO_MAP` di `AudioManager.gd`, pool 8 player, bus Master/Music/SFX). **[NOT IMPLEMENTED]** musik ambient — `Preview.ogg` hanya demo mashup, bukan loop; kebutuhan loop desa/hutan/dungeon CC0 masih terbuka.

## 11. Uji & batas jujur

Headless + soak dilaporkan hijau di `docs/ANDROID_TEST_PLAN.md` (B2/B3/B4/B5 + soak Main 3600 frame 0 error) — uji editor/perangkat fisik tetap wajib sebelum klaim rilis. APK lokal belum ada (`Build/` kosong); selisih target 100 MB jujur di `CONTENT_PACKS.md` §3 dan `CHANGELOG.md`. Tidak ada klaim "teruji di perangkat" di sesi ini.
