# ASSET CREDITS — Mythfall: Echoes of Aether

Semua paket di bawah oleh **Kenney Vleugels (www.kenney.nl)**,
lisensi **Creative Commons Zero (CC0)** — terverifikasi di halaman resmi
masing-masing (tertulis "CC0 licensed"). Kredit tidak wajib, dicantumkan
sebagai penghargaan. Teks lisensi asli disalin ke `LICENSES/`.

| Paket | Source | Dipakai di Phase A | Target di proyek |
|---|---|---|---|
| Roguelike RPG Pack | https://kenney.nl/assets/roguelike-rpg-pack | `Sample1.png` (placeholder art, Main) | `Assets/Environment/RoguelikeRPG/` |
| Tiny Town | https://kenney.nl/assets/tiny-town | `Sample.png` (banner, MainMenu) | `Assets/Environment/TinyTown/` |
| Roguelike Characters | https://kenney.nl/assets/roguelike-characters | belum di-wire (Phase B) | `Assets/Characters/Roguelike/` |
| Fantasy UI Borders | https://kenney.nl/assets/fantasy-ui-borders | belum di-wire (Phase B) | `Assets/UI/FantasyBorders/` |
| RPG Audio | https://kenney.nl/assets/rpg-audio | belum di-wire (Phase B) | `Assets/Audio/RPG/` |
| Roguelike Caves & Dungeons | https://kenney.nl/assets/roguelike-caves-dungeons | `roguelikeDungeon_transparent.png` (basalt Emberfall) | `Assets/Environment/Caves/` (32.172 B) |
| RPG Urban Pack | https://kenney.nl/assets/rpg-urban-pack | `tilemap_packed.png` (pos Emberfall) | `Assets/Environment/Urban/` (18.270 B) |
| Foliage Pack | https://kenney.nl/assets/foliage-pack | `foliagePack_default.png` (hangus Emberfall) | `Assets/Environment/Foliage/` (171.275 B, default saja) |
| UI Pack RPG Expansion | https://kenney.nl/assets/ui-pack-rpg-expansion | subset bar/button 9-slice (HUD) | `Assets/UI/RPGExpansion/` (12.666 B) |
| Impact Sounds | https://kenney.nl/assets/impact-sounds | footstep/impact (AudioManager) | `Assets/Audio/Impacts/` (70.378 B) |
| Floor Is Lava (static) | https://opengameart.org/content/floor-is-lava (Kipperfalcon, CC0, tanpa file lisensi — URL+CC0 tercatat) | `floor_is_lava.png` crust static Emberfall | `Assets/Environment/Emberfall/` (7.678 B dgn .import) |
| LPC Animated Lava 45f | https://lpc.opengameart.org/content/16x16-and-animated-lava-tile-45-frames (davesch, CC0, tanpa file lisensi — URL+CC0 tercatat) | `lava_spr_strip45.png` 2 pool anim Emberfall | `Assets/Environment/Emberfall/` (18.192 B dgn .import) |
| Loopable Dungeon Ambience | https://opengameart.org/content/loopable-dungeon-ambience (JaggedStone, CC0, tanpa file lisensi — URL+CC0 tercatat) | ambient Emberfall/crypt 94,3 dtk | `Assets/Audio/Ambience/` (1.626.780 B dgn .import) |
| 16x16 Water/Grass/Sand | https://opengameart.org/content/16x16-tileset-water-grass-and-sand (Demetrius, CC0, tanpa file lisensi — URL+CC0 tercatat) | `desert_sand.png` tiles Luminara | `Assets/Environment/Luminara/` (4.012 B dgn .import) |

E2 runtime: `Scenes/World/EmberfallHighlands.tscn` (8.987 B) + `Scenes/Enemies/EmberWisp.tscn` (1.764 B) + `Scripts/World/EmberfallHighlands.gd` (1.494 B) + `Data/Regions/emberfall_highlands.tres` (458 B) + `Data/Enemies/ember_wisp.tres` (563 B). Total subset Emberfall 318.047 B (`du`). URL zip + sha256 terverifikasi: lihat `Sources/SOURCING_LOG.md` §1 + `ASSET_MANIFEST.json`.

F2 runtime: `Scenes/World/LuminaraDesert.tscn` (9.235 B) + `Scripts/World/LuminaraDesert.gd` (1.134 B) + `Data/Regions/luminara_desert.tres` (446 B) + lava/ambient/desert di atas. Total subset Luminara 1.667.496 B (`du` 6 contents). 32px-zip DITOLAK + Foozle GAGAL: hanya `Sources/SOURCING_LOG.md` §6, TIDAK masuk manifest/kredit runtime.

Detail ukuran & sha256: lihat `ASSET_MANIFEST.json`.
