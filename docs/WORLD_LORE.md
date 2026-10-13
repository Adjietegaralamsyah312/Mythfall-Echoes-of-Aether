# WORLD_LORE — Mythfall: Echoes of Aether

Sumber: `Scenes/NPC/*.tscn`, `Scenes/World/DawnrootValley.tscn`, `Data/Quests/*.tres`, `Data/Items/*.tres`, `Data/Regions/*.tres`. Hanya yang tertulis di file dicatat sebagai kanon. Sisanya = **Proposal**.

Istilah konsisten dengan `GAME_DESIGN_DOCUMENT.md` dan `WORLD_MAP.md`: Dawnroot Valley, Dawnroot Crypt (`dungeon_id dawnroot_crypt`), Aether, Aether Shard, Elder Maren, Bram, Sari, Elite Dawnroot Guardian.

## 1. Premis kanon (dari quest + NPC)

Aether pecah; akar Dawnroot melemah; slime meluap dari hutan; pecahan Aether berserakan; ruang bawah Dawnroot Crypt tersegel lalu terbuka setelah hutan aman; pengelana membantu desa dan melawan penjaganya.

Bukti dialog (`Data/Quests/*.tres`, Bahasa Indonesia asli):

- Intro terima: "Selamat datang di Dawnroot, pengelana." / "Aku Maren, tetua desa ini. Akar kami melemah sejak pecahnya Aether." / "Bantu kami, dan desa ini akan mengingat namamu." Selesai: "Bagus. Kau mau mendengar, itu langkah pertama." / "Ambil ramuan ini. Hutan liar menunggumu."
- Wilds terima: "Slime meluap dari hutan dan pecahan Aether berserakan." / "Kalahkan 3 slime dan kumpulkan 2 pecahan Aether untukku." / "Hanya slime dan pecahan asli yang kuhitung. Hati-hati di sana." Selesai: "Hutan bisa bernapas lagi berkatmu." / "Pedang tua ini kini milikmu. Gunakan dengan baik."
- Sealed terima: "Di bawah reruntuhan ada ruang bawah yang tersegel: Dawnroot Crypt." / "Segelnya terbuka untukmu setelah hutan aman. Masuk dan hadapi penjaganya." / "Kalahkan Elite Dawnroot Guardian dan kembali dengan kabar kemenangan." Selesai: "Ruang bawah sunyi lagi. Dawnroot berutang padamu." / "Helm penjaga ini pantas kau sandang."

## 2. Tokoh kanon

- `elder_maren` — "Elder Maren", tetua desa, pemberi 3 quest (`giver_npc_id`), posisi valley `(640,1000)`. Idle: "Desa Dawnroot bertahan karena Aether yang mengalir di akarnya." / "Bicaralah padaku jika kau siap membantu, pengelana." / "Hutan di luar pagar tak lagi aman seperti dulu."
- `villager_bram` — "Bram", posisi `(520,1090)`. Idle: "Panen kali ini lumayan, walau slime merusak pagar ladang." / "Kalau mau ke hutan, bawa ramuan. Percayalah." / "Elder Maren tahu segalanya soal Dawnroot."
- `villager_sari` — "Sari", posisi `(760,1090)` (override di valley). Idle: "Aku menjaga lumbung selagi kakakku Bram di ladang." / "Pecahan Aether berpendar di hutan malam hari." / "Jangan pergi jauh tanpa pamit pada Elder Maren." Hubungan kakak-beradik Sari↔Bram hanya dari kalimat Sari; tidak ada file hubungan lain.

Tidak ada faksi, sejarah kerajaan, atau tokoh lain di file — jangan karang.

## 3. Benda & tempat kanon

- `aether_shard` — "Aether Shard", currency/quest-item: "Fragmen Aether. Currency/quest-item Dawnroot."
- `health_potion` — "Health Potion", consumable: "Memulihkan 30 HP. (Efek pakai di B5.)"
- `rusty_sword` — "Rusty Sword", weapon: "Pedang tua. Bonus damage +3 saat equipment jadi (B5)."
- `guard_helm` — "Guard Helm", armor: "Helm penjaga. Efek armor saat equipment jadi (B5)."
- Musuh kanon: Slime, Skeleton, Aether Wisp, Elite Dawnroot Guardian (stat: GDD §6).
- Tempat kanon: Dawnroot Valley (desa selatan, hutan, reruntuhan, encounter, chest, entrance) + Dawnroot Crypt (checkpoint, elite, reward chest, exit). Koordinat: `WORLD_MAP.md`.

## 4. Rantai quest kanon

`dawnroot_intro` (talk elder_maren ×1, tanpa prereq, reward 20 XP + 1 potion) → `dawnroot_wilds` (prereq intro; kill slime ×3 + collect shard ×2; reward 60 XP + sword) → `dawnroot_sealed_dungeon` (prereq wilds; enter crypt ×1 + kill_elite elite ×1; reward 120 XP + helm). Hanya slime/shard asli dihitung; skeleton salah tak majukan slime.

## 5. Proposal (bukan kanon)

Usulan lore baru (nama 5 region ekspansi, faksi, sejarah, boss akhir) ditulis di sini saja setelah pemilik setuju, dan wajib diikuti integrasi scene/quest nyata sebelum dipindah ke §1–§4. Saat ini: kosong — belum ada usulan disetujui.
