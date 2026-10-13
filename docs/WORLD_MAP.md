# WORLD_MAP — Mythfall: Echoes of Aether

Sumber: `Data/Regions/*.tres`, `Scenes/World/DawnrootValley.tscn`, `Scenes/Dungeon/DawnrootCrypt.tscn`, `Scenes/World/EmberfallHighlands.tscn`, `Scripts/World/Main.gd` + `RegionManager.gd`, `Data/Packs/*.tres`, `docs/CONTENT_PACKS.md`. Satuan: piksel Godot, origin kiri-atas.

> Emberfall kini playable lokal; 4 ekspansi lain tetap rencana. Lihat status §4.

## 1. Dawnroot Valley — PLAYABLE

- Batas: `limit 0,0,2560,1440` (`dawnroot_valley.tres`). Spawn + checkpoint `(640,1150)`.
- Desa selatan (y 840–1440): rumah `(380,1120)`, `(900,1120)`, `(1140,940)`; gerbang batu `(640,880)`; Elder Maren `(640,1000)`; Bram `(520,1090)`; Sari `(760,1090)`; crate `(580,1010)`, `(700,1010)`.
- Hutan + reruntuhan (y <840): pohon/pine/semak/hedge tersebar (mis. pohon `(420,560)`, `(700,480)`, `(900,620)`); reruntuhan `(560,240)`, `(720,240)`, `(640,300)`; jalan paver x ~640 dari y 370–820.
- Encounter: `SlimeSpawn1 (420,520)`, `SkeletonSpawn1 (860,520)`, `WispSpawn1 (640,340)` → dipetakan `ENCOUNTER_MAP` di `Main.gd`.
- Chest: `ValleyChest (1000,720)` = 2 shard + 1 potion, sekali-ambil.
- Entrance: `DungeonEntrance Area2D (640,150)` 120×70 label "DAWNROOT CRYPT" → `travel_to(dawnroot_crypt)`. Dinding: `2592×32` / `32×1472`.

## 2. Dawnroot Crypt — PLAYABLE (`dungeon_id dawnroot_crypt`)

- Batas: `limit 0,0,1280,720` (`dawnroot_crypt.tres`). Spawn + checkpoint `(640,560)`.
- Spawn musuh: `EliteSpawn1 (640,200)`, `SkeletonSpawn1 (520,260)`, `SkeletonSpawn2 (760,260)`; lantai/obor/pilar dekoratif sekitar y 110–480.
- Reward: `CryptRewardChest (640,110)` = 1 helm + 1 sword, sekali-ambil.
- Checkpoint: `CheckpointZone (640,560)` 140×80 → `reach_checkpoint` + autosave (Main).
- Exit: `ExitPortal (640,670)` 120×50 label "KELUAR — VALLEY" → kembali valley `VALLEY_RETURN_POS (640,300)`. Dinding: `1312×32` / `32×752`.
- Koneksi dua arah: `dawnroot_valley.dungeon_ref = dawnroot_crypt`, sebaliknya `dawnroot_crypt.dungeon_ref = dawnroot_valley`; quest `enter dawnroot_crypt` + `kill_elite elite_dawnroot` dihitung di sini.

## 3. Koneksi

Valley `(640,150)` → Crypt `(640,560)` → Elite `(640,200)` → Chest `(640,110)` → Checkpoint `(640,560)` → Exit `(640,670)` → Valley `(640,300)`. Mati → respawn di checkpoint terakhir (`Player.respawn`).

## 3b. Emberfall Highlands — PLAYABLE LOKAL

- Batas: `limit 0,0,1920,1080` (`emberfall_highlands.tres`). Spawn + checkpoint `(960,900)`.
- Portal masuk: Valley `EmberPortal (1000,150)` → `travel_to(emberfall_highlands)`; keluar: Emberfall `ExitPortal (960,1000)` → Valley `(640,300)`.
- Encounter: `SkeletonSpawn1 (700,600)`, `SkeletonSpawn2 (820,650)`, `EmberSpawn1 (1200,500)`, `EmberSpawn2 (1320,560)`, `EliteSpawn1 (1260,400)` → `EmberWisp` (ranged) via `ENCOUNTER_MAP`.
- Chest: `EmberChest (960,250)` = 3 shard + 1 potion, sekali-ambil. Checkpoint: `(960,900)` 140×80.

## 4. Status region

| Region | Status | Bukti |
|---|---|---|
| `dawnroot_valley` | PLAYABLE | `.tres` + `DawnrootValley.tscn` + `initial` BUILT_IN |
| `dawnroot_crypt` | PLAYABLE | `.tres` + `DawnrootCrypt.tscn` + `initial` BUILT_IN |
| `emberfall_highlands` | PLAYABLE LOKAL (UNAVAILABLE-unduh) | `emberfall_highlands.tres` + `EmberfallHighlands.tscn` + portal dua arah Valley (1000,150) <-> Exit (960,1000) |
| `luminara_desert` | RENCANA | hanya di `luminara.tres`, tanpa scene |
| `veilwood_forest` | RENCANA | hanya di `veilwood.tres`, tanpa scene |
| `azure_shattercoast` | RENCANA | hanya di `azure.tres`, tanpa scene |
| `aether_crown` | RENCANA (endgame) | hanya di `aether_crown.tres`, tanpa scene |

Paket: `initial` (BUILT_IN, 3.369.507 B union, termasuk subset Emberfall 318.047 B) vs 4 paket ekspansi UNAVAILABLE + `emberfall` UNAVAILABLE-unduh tapi playable lokal. Jangan hitung `.git`/`.godot`/arsip tak terpakai sebagai konten. Penuh: `CONTENT_PACKS.md`.
