# ARCHITECTURE — Phase A (minimal)

Modul (lihat struktur `Scenes/` + `Scripts/`):

- `Scripts/Core/Boot.gd` — entry: self-check MainMenu ada → pindah scene.
- `Scripts/UI/MainMenu.gd` — menu: hanya New Game navigasi nyata.
- `Scripts/World/Main.gd` — world placeholder: kamera + HUD versi.

Signal: hanya bawaan Godot (`Button.pressed`) di Phase A.
Tanpa autoload, tanpa singleton. Sistem Phase B (player, combat, save,
quest) belum ada — jangan klaim.
