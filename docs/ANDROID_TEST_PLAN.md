# ANDROID TEST PLAN — Mythfall v0.5.0-b5 (Phase B akhir)

Alat: Godot Editor Android (Play Store), perangkat landscape. Headless
CLI (Termux `godot --headless`) SUDAH hijau: B2/B3/B4/B5 + soak Main
3600 frame 0 error. Bagian bawah = checklist plan seksi 19.

## 0. Buka proyek
1. Editor Android → Open → `/storage/emulated/0/Download/Mythfall_Echoes_of_Aether`.
2. Tunggu import selesai; pastikan 0 error import.
3. Jalankan `Scenes/MainMenu/MainMenu.tscn` (F5/play scene utama).

## 1. Landscape (wajib)
- Putar perangkat: portrait → landscape → portrait. Layout tak rusak,
  tak ada overflow horizontal, tombol tetap ≥64px.
- Notch/cutout: HUD kiri (HP/Stamina/Lv) dan tracker kanan tak tertutup.
- `project.godot`: orientation=landscape, viewport 1280x720, stretch canvas_items/expand.

## 2. MainMenu
- New Game → masuk valley di spawn (640,1150).
- Continue DISABLE + status jujur bila belum ada save.
- Settings: ubah Master/Musik/SFX → tersimpan; Quality Low matikan partikel.
- Credits: daftar CC0 Kenney/OGA + musik CC0 BULK-001 (jujur).
- Quit menutup aplikasi.

## 3. Sentuh (TouchControls jangan rusak)
- Joystick kiri: 8 arah, multitouch (gerak + ATK bersamaan).
- ATK/DGE/SKL/INT/II respons + bunyi klik (metalClick).
- Sensitivitas 50–150% terasa bedanya.
- Keyboard tetap jalan (WASD/Space/F/Q/P) untuk uji editor.

## 4. Quest (3 quest, Bahasa Indonesia)
- Bicara Elder Maren → intro selesai; bicara lagi → wilds aktif.
- Bunuh skeleton SALAH tak majukan slime; potion tak majukan shard.
- 3 slime + 2 shard → wilds selesai (reward rusty_sword).
- Tracker kanan ringkas 1 quest + tombol minimize; Quest Log (tombol Quest/Q)
  tampilkan Tersedia/Aktif/Selesai + state kosong jujur.
- DialoguePanel: nama + Lanjut/Tutup, sentuh + keyboard (F/Enter).

## 5. Combat + VFX + Audio
- Swing bunyi drawKnife; kena bunyi knifeSlice + spark + damage number.
- Terluka bunyi cloth (fallback, catat); mati musuh bunyi chop + poof.
- Skill cooldown bar terisi; dodge iframes terasa.
- Quality Low: tak ada partikel; Balanced/High: spark wajar.

## 6. Dungeon + checkpoint + autosave
- Masuk DungeonEntrance → crypt, bunyi pintu, quest enter tercatat [1,0].
- Elite + 2 skeleton; bunuh elite → dungeon selesai + guard_helm.
- Reward chest → rusty_sword; keluar ExitPortal → valley, ValleyChest
  tetap terbuka.
- Sentuh checkpoint → autosave diam-diam (cek file `user://mythfall_save.cfg`).

## 7. Save/Load
- Pause (Jeda/P) → Simpan → popup "Progres tersimpan." (bukan fake).
- Menu Utama → Continue aktif → posisi/level/inventory/quest/region pulih.
- Rusak manual: tulis sampah ke save → Continue disable + pesan jujur,
  New Game aman (fallback teruji headless B5).

## 8. Minimap (200px, tak penuhi layar)
- Titik putih player, hijau NPC, kuning objective; toggle Peta.
- Hanya discovered; tak menutup joystick/tombol.

## Checklist plan seksi 19 (ringkas)
- [x] project.godot valid (headless --import exit 0)
- [x] referensi script/scene/texture/audio (grep res:// none missing)
- [x] path resource + node path (B2/B3/B4 hijau)
- [x] signal connections (main soak 0 error)
- [x] input actions (uji §3)
- [x] collision layers/masks (musuh lukai player, proyektil team-check B2)
- [x] landscape (§1)
- [x] save/load (§7, B5)
- [x] item pickup, enemy damage/death, quest progress, dungeon, inventory penuh (B2/B3/B4)
- [ ] content manifest + SHA-256 (milik pipeline aset, luar B5)
- [ ] Android export/APK (Phase C, BELUM — jangan klaim)
- [ ] uji perangkat fisik (BELUM — butuh Editor Android manual)
