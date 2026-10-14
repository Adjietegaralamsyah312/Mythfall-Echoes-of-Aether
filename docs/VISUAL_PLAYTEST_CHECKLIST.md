# VISUAL PLAYTEST CHECKLIST — Mythfall: Echoes of Aether (Phase F)

Uji di **Godot Editor Android** (jalankan Main) dan **APK debug di perangkat**.
Centang hanya yang benar-benar terlihat. Headless TIDAK bisa memverifikasi visual.

## 0. Setup
- [ ] Import `project.godot` bersih, tanpa error merah.
- [ ] Jalankan `Scenes/World/Main.tscn` landscape (1280×720 dan rasio HP, mis. 20:9).

## 1. Player animation (F-A, prosedural — bukan frame art)
- [ ] Idle: napas halus, kembali ke pose netral.
- [ ] Jalan 8 arah: bob+tilt ikut kecepatan, flip kiri/kanan benar.
- [ ] Attack: lunge terasa SELARAS dengan kena hit (tak ada visual kena duluan).
- [ ] Dodge: stretch 0,22 dtk, transparan selama iframe, tak teleport/nabrak aneh.
- [ ] Hurt: flash + goyang, tak bisa attack saat hurt.
- [ ] Death: jatuh/fade, tak bisa gerak/attack; respawn pop di checkpoint.

## 2. Enemy animation (F-B, prosedural)
- [ ] Slime: squash idle, jongkok wind-up TERBACA, kempis saat mati.
- [ ] Skeleton/Elite: telegraph getar sebelum tebas, roboh saat mati.
- [ ] Wisp/Ember: hover, charge mengembang sebelum cast, menyusut+naik saat mati.
- [ ] Musuh mati tak pernah kembali idle/attack.

## 3. Combat feedback + kamera (F-C)
- [ ] Hit flash singkat, tak menutupi karakter.
- [ ] Slash + partikel + damage number terbaca (max 8, tak penuhi layar).
- [ ] "MISS" abu-abu saat dodge sempurna.
- [ ] Cooldown skill jelas (hijau SIAP / kuning / merah + teks detik).
- [ ] Kamera: tak sentak, tak lag berlebih, snap halus saat respawn/transisi.
- [ ] Shake HANYA saat hit besar (≥20), mati di kualitas Low.

## 4. World presentation (F-D + V-FIX)
- [ ] Spawn Valley: tanah coklat + paver + bush (BUKAN void hitam).
- [ ] Tak ada strip void saat kamera di tepi / rasio lebar.
- [ ] Crypt chest utuh, tak terpotong tepi atas.
- [ ] Toolbar Quest/Jeda/Musik di tengah-atas; HUD tak tutup player.
- [ ] TERBUKA (belum dikerjakan, butuh verifikasi visual): Y-sort occlusion
      (player di belakang pohon/bangunan), Light2D/bayangan.

## 5. Ambience (F-D)
- [ ] Valley: daun jatuh; Crypt: debu; Emberfall: bara naik; Luminara: debu.
- [ ] Audio: valley/luminara BGM, emberfall/crypt ambient gua, tanpa overlap.
- [ ] Quality Low: ambience MATI, gameplay tetap jalan.
- [ ] Ambience berhenti saat ganti region (tak ada suara/partikel nyasar).

## 6. UI readability
- [ ] HP/Stamina/XP/cooldown terbaca di 1280×720 dan HP kecil.
- [ ] Tombol ≥64px, joystick nyaman, panel tak terpotong di 16:9–20:9.
- [ ] Skala UI minimum 0,8; teks dialog/quest terbaca.
- [ ] Musik panel: 30 trek, now-playing benar, Stop/Tutup bekerja.

## 7. Performa (jangan klaim angka tanpa ukur)
- [ ] Combat 3+ musuh: input tetap responsif.
- [ ] Quality Low/Balanced/High diterapkan tanpa restart.
- [ ] Catat perangkat + hasil: ____ (model, Android, FPS terasa, panas).

## 8. Menu (V-004)
- [ ] Screenshot SISTEM (bukan foto): pastikan garis lengkung kiri-atas hilang.
