MASTER ENGINEERING PROMPT

MYTHFALL: ECHOES OF AETHER

Mobile Open-World Action RPG — Godot 4 / GDScript

Anda bertindak sebagai Principal Game Engineer, Godot Gameplay Programmer, Technical Artist, Mobile Optimization Engineer, Game Systems Architect, Asset Pipeline Engineer, QA Engineer, dan GitHub Release Engineer.

Tanggung jawab Anda adalah membangun proyek game yang nyata, dapat dibuka di Godot Editor Android, dapat dimainkan pada perangkat Android landscape, terstruktur untuk pengembangan jangka panjang, dan memiliki jalur build APK yang dapat diverifikasi.

Jangan berhenti pada pembuatan dokumen, contoh kode, mockup, atau rencana teknis. Prioritaskan fondasi proyek yang valid, implementasi gameplay yang berfungsi, integrasi aset nyata, pengujian, dan distribusi.

1. PROJECT IDENTITY

Nama game:
Mythfall: Echoes of Aether

Nama proyek:
"Mythfall_Echoes_of_Aether"

Android application ID:
"com.mythfall.echoesofaether"

Kategori:
Single-player Open-World Action RPG.

Platform distribusi:
Android.

Target bahasa pemrograman:
GDScript untuk Godot 4.

Target lokasi proyek:
"/storage/emulated/0/Download/Mythfall_Echoes_of_Aether"

Lingkungan pengembangan:

- Termux untuk akses filesystem, Git, dan perintah terminal.
- OpenCode untuk membuat, mengedit, dan memperbaiki file proyek.
- Godot Editor Android dari Google Play Store untuk membuka proyek, mengimpor resource, menjalankan permainan, dan mengekspor Android jika didukung oleh versi terpasang.
- GitHub untuk penyimpanan source code, version control, dokumentasi, CI, dan distribusi build.

Proyek harus benar-benar baru.

LARANGAN KERAS:

- Jangan menggunakan, membaca sebagai basis implementasi, menyalin kode, atau memodifikasi proyek Elaria.
- Jangan menggabungkan direktori proyek ini dengan game terdahulu.
- Jangan menggunakan C# atau membuat proyek Godot .NET.
- Jangan membutuhkan Termux:X11, desktop Linux, VNC, atau editor desktop.
- Jangan menjadikan keyboard dan mouse sebagai kontrol utama permainan.
- Jangan menjadikan website atau game berbasis browser sebagai pengganti game Android native.
- Jangan mengklaim APK telah dibuat jika file APK belum benar-benar dihasilkan.
- Jangan mengklaim fitur telah selesai hanya karena script atau scene telah dibuat.

2. ENVIRONMENT AND COMPATIBILITY

Sebelum implementasi:

1. Periksa direktori kerja dan pastikan berada di folder proyek yang ditentukan.
2. Identifikasi apakah folder telah berisi proyek atau file sebelumnya. Jangan menghapus data yang sudah ada.
3. Periksa versi Godot Editor yang akan digunakan jika informasinya tersedia.
4. Targetkan proyek Godot 4 yang kompatibel dengan versi stabil Godot Editor Android pengguna.
5. Gunakan GDScript Godot 4 dengan sintaks, API, signal, resource, dan tipe data yang benar.
6. Jangan menggunakan properti atau API yang hanya tersedia pada versi Godot yang lebih baru daripada editor pengguna.
7. Buat "project.godot" dan konfigurasi proyek yang dapat dibuka oleh Godot Editor Android.
8. Jangan mensyaratkan executable Godot Linux yang tidak tersedia di Termux.
9. Jika Godot CLI tidak tersedia, jangan berpura-pura sudah menjalankan pengujian engine. Lakukan pemeriksaan statis dan dokumentasikan pengujian yang perlu dilakukan dalam Godot Editor Android.
10. Gunakan renderer Mobile sebagai pilihan awal apabila cocok dengan perangkat Android sasaran. Hindari Forward+ sebagai default untuk perangkat ini; gunakan Compatibility jika pengujian menunjukkan masalah kompatibilitas atau performa.
11. Gunakan fitur bawaan Godot selama memungkinkan. Hindari ketergantungan plugin yang tidak diperlukan.
12. Simpan setiap file hasil implementasi langsung dalam workspace proyek.

Buat dokumen "docs/ENVIRONMENT.md" yang mencatat asumsi versi engine, renderer, target Android, dan langkah membuka proyek.

3. GAME DESIGN VISION

Buat action RPG open-world fantasi dengan gaya visual:

HD-2D Pixel-Modern Mewah

Gaya ini menggabungkan:

- Pixel art dengan bentuk dan siluet yang konsisten.
- Perspektif top-down/three-quarter dengan kedalaman visual.
- Lingkungan yang memiliki foreground, gameplay plane, dan background.
- Y-sorting dan occlusion agar karakter bergerak secara alami di antara objek.
- Dynamic 2D lighting, bayangan, kabut, partikel, dan atmosfer.
- Color grading yang terkontrol.
- Efek combat yang memiliki impact visual.
- UI premium dengan komposisi, hierarki, tipografi, dan animasi yang baik.
- Eksplorasi dunia dengan lingkungan yang terasa hidup.

Gunakan pencahayaan dan efek yang meningkatkan pixel art, bukan mengaburkan bentuk pixel.

Jangan membuat semua tiles memiliki ukuran, perspektif, atau proporsi berbeda tanpa proses penyesuaian. Gunakan ruleset visual yang konsisten untuk semua region.

Gunakan pixel-perfect rendering atau pendekatan yang sesuai dengan aset sumber. Jangan melakukan interpolasi tekstur yang menyebabkan pixel art menjadi blur.

Apabila suatu fitur grafis mahal, sediakan pilihan kualitas Low, Balanced, dan High. Pertahankan identitas visual pada semua tingkat kualitas.

Hindari efek glow, blur, partikel, atau shader yang berlebihan hingga mengganggu gameplay maupun frame rate.

4. OFFICIAL ASSET SOURCES — FIVE REQUIRED PACKS

Evaluasi dan integrasikan lima paket berikut terlebih dahulu.

Asset 1 — Roguelike/RPG Pack

URL:
https://kenney.nl/assets/roguelike-rpg-pack

Tujuan:
Tile, objek lingkungan, dekorasi, dan bahan dasar dunia RPG.

Asset 2 — Tiny Town

URL:
https://kenney.nl/assets/tiny-town

Tujuan:
Bangunan, desa, pemukiman, dan elemen overworld.

Asset 3 — Roguelike Characters

URL:
https://kenney.nl/assets/roguelike-characters

Tujuan:
Bahan sprite karakter dan NPC, serta kandidat sprite musuh jika sesuai.

Asset 4 — Fantasy UI Borders

URL:
https://kenney.nl/assets/fantasy-ui-borders

Tujuan:
Panel dialog, bingkai UI, inventori, dan antarmuka fantasi.

Asset 5 — RPG Audio

URL:
https://kenney.nl/assets/rpg-audio

Tujuan:
Efek suara langkah kaki, senjata, combat, dan interaksi yang cocok.

Prosedur integrasi:

1. Akses halaman resmi masing-masing paket.
2. Verifikasi lisensi dan tautan unduhan pada halaman resmi.
3. Unduh arsip yang tersedia secara legal.
4. Jangan mengarang URL download.
5. Periksa format arsip dan integritas sebelum mengekstrak.
6. Ekstrak aset ke direktori yang sesuai di dalam "Assets/".
7. Periksa spritesheet, tile size, transparansi, animasi, resolusi, dan format audio.
8. Tentukan aset mana yang cocok berdasarkan gameplay dan art direction.
9. Integrasikan aset ke scene dan sistem game yang benar-benar digunakan.
10. Catat aset yang gagal diunduh, gagal diekstrak, atau tidak cocok.
11. Jangan mengklaim suatu paket telah terpasang jika file sebenarnya tidak tersedia.
12. Jika download terhambat, teruskan pekerjaan yang tidak bergantung pada paket tersebut dan berikan URL sumber untuk penyelesaian manual.

Paket-paket tersebut merupakan titik awal, bukan jaminan bahwa semua kebutuhan seni game sudah terpenuhi.

Jangan mengubah aset secara membabi buta atau menggabungkan spritesheet tanpa memahami struktur animasinya.

Jika diperlukan, buat variasi lingkungan melalui komposisi tile, palette variation, shader, pencahayaan, dan dekorasi tambahan yang benar-benar digunakan.

Aset tambahan harus berasal dari sumber yang mengizinkan penggunaan dan redistribusi yang sesuai. Prioritaskan CC0, lalu lisensi permisif yang kompatibel. Verifikasi setiap lisensi secara terpisah.

Buat file berikut:

- "ASSET_CREDITS.md"
- "ASSET_MANIFEST.json"
- "LICENSES/"
- "docs/ASSET_PIPELINE.md"

Manifest setidaknya mencatat nama aset, sumber URL, lisensi, file yang digunakan, ukuran aktual, dan SHA-256 apabila tersedia.

Jangan memasukkan aset yang tidak diketahui asal atau lisensinya.

5. ART DIRECTION AND TECHNICAL ART

Bangun art pipeline yang konsisten.

Wajib:

- Gunakan palette warna terencana.
- Tentukan aturan ukuran dan grid tile.
- Tentukan pendekatan animasi karakter.
- Tentukan urutan layer lingkungan.
- Tentukan aturan sorting objek.
- Tentukan pencahayaan untuk area indoor dan outdoor.
- Gunakan collision yang sesuai dengan bentuk gameplay.
- Pastikan objek dekoratif tidak secara keliru menghalangi pemain.
- Gunakan partikel secara selektif.
- Gunakan animasi UI yang tidak mengganggu responsivitas.
- Buat material atau shader reusable jika benar-benar dibutuhkan.
- Sediakan pengaturan efek grafis yang ringan untuk Android.

Buat "docs/ART_DIRECTION.md".

Jika aset sumber tidak memiliki animasi yang diperlukan, periksa apakah animasi dapat dibuat dari frame yang tersedia. Jangan menyatukan frame yang tidak berurutan menjadi animasi palsu.

Jika perlu membuat aset orisinal tambahan, simpan source atau generator yang digunakan sehingga aset dapat diproduksi ulang.

Jangan mengklaim bahwa aset buatan otomatis setara dengan produksi art profesional tanpa evaluasi visual.

6. GAME WORLD AND LORE

Bangun dunia fantasi orisinal bernama Mythfall.

Aether adalah sumber kekuatan yang menjaga keseimbangan berbagai kawasan. Sebuah bencana memecah inti Aether dan membuat beberapa wilayah mengalami perubahan. Reruntuhan kerajaan, makhluk berbahaya, dungeon tersegel, dan rahasia kuno muncul kembali.

Pemain berperan sebagai pengelana yang dapat berinteraksi dengan fragmen Aether. Perjalanan mencakup eksplorasi, pertarungan, pengumpulan equipment, penyelesaian quest, penemuan rahasia, dan pemulihan wilayah.

Rencanakan enam region utama:

1. Dawnroot Valley — desa awal, hutan, sungai, ladang, dan reruntuhan.
2. Emberfall Highlands — gunung vulkanik, gua, benteng, dan jalur berbahaya.
3. Luminara Desert — pasir, oasis, kota dagang, serta reruntuhan bawah tanah.
4. Veilwood Forest — hutan misterius, kabut, flora unik, dan jalur tersembunyi.
5. Azure Shattercoast — pesisir, pelabuhan, pulau, dan gua kristal.
6. Aether Crown — kawasan endgame, musuh elite, dungeon kuno, dan boss utama.

Semua region harus memiliki identitas visual, encounter, NPC, loot, quest, dan tujuan eksplorasi yang sesuai.

Untuk vertical slice pertama, implementasikan Dawnroot Valley dengan baik. Region lain harus ditambahkan melalui arsitektur yang dapat dikembangkan, bukan sekadar kumpulan scene kosong yang diklaim telah selesai.

Buat:

- "docs/GAME_DESIGN_DOCUMENT.md"
- "docs/WORLD_LORE.md"
- "docs/WORLD_MAP.md"

7. ANDROID-ONLY LANDSCAPE REQUIREMENTS

Game diperuntukkan khusus untuk Android landscape.

Wajib:

- Orientasi landscape dikonfigurasi pada project settings dan Android export preset yang didukung versi Godot.
- Portrait tidak boleh menjadi mode gameplay.
- Uji orientasi sebenarnya, bukan hanya ukuran viewport editor.
- Pastikan UI berfungsi pada rasio layar landscape yang berbeda.
- Gunakan safe area untuk menghindari notch, cutout, serta area tepi.
- Tangani perubahan orientasi perangkat agar tidak merusak layout.
- Sesuaikan anchor, margin, dan scaling UI dengan benar.
- Hindari interface desktop seperti tombol keyboard wajib, pointer desktop, atau menu yang hanya bisa digunakan melalui hover.
- Gunakan tombol yang nyaman untuk sentuhan.
- Pastikan game pause dan resume dengan benar ketika aplikasi Android berpindah ke background lalu kembali.
- Jangan memerlukan permission Android yang tidak diperlukan.

Buat menu:

- New Game.
- Continue.
- Settings.
- Credits.
- Quit/Return sesuai perilaku Android yang tepat.

Tambahkan pengaturan:

- Master volume.
- Music volume.
- Sound effects volume.
- Sensitivitas kontrol.
- Kualitas efek visual.
- Ukuran atau skala UI jika sesuai.

Jangan menganggap game sudah landscape-only sebelum konfigurasi ekspor dan hasil aplikasi diperiksa.

8. MOBILE CONTROLS

Semua sistem inti harus bisa dimainkan dengan layar sentuh.

Kontrol utama:

- Virtual joystick di sisi kiri.
- Basic attack di sisi kanan.
- Dodge/roll.
- Skill.
- Interact.
- Inventory.
- Quest log.
- Map.
- Pause.

Ketentuan:

- Dukungan multitouch.
- Joystick memiliki area sentuh yang wajar.
- Tombol dapat ditekan secara konsisten ketika pemain sedang bergerak.
- Tombol utama tidak terlalu berdekatan.
- UI tidak menutupi karakter, target, atau objek penting.
- Feedback visual dan audio ketika tombol diaktifkan.
- Jangan mensyaratkan keyboard untuk melanjutkan permainan.
- Input system tetap mudah diuji dan dipelihara.

9. PLAYER AND CHARACTER SYSTEM

Implementasikan karakter utama dengan node dan sistem yang sesuai dengan Godot 4.

Fitur:

- Gerakan delapan arah.
- Collision dan movement yang stabil.
- Kamera mengikuti karakter dengan smoothing terkontrol.
- Idle dan movement animation.
- Basic attack.
- Dodge/roll.
- Health dan stamina.
- Damage feedback.
- Kematian dan respawn.
- Interaksi dengan NPC, chest, loot, pintu, dan objek quest.

Gunakan "CharacterBody2D" bila sesuai dengan arsitektur gerakan yang dipilih.

Pisahkan movement, combat, stats, inventory, interaction, dan progression ke modul yang terorganisasi. Jangan membuat satu script raksasa berisi seluruh sistem game.

10. COMBAT AND ENEMY AI

Buat combat yang responsif dan teruji.

Basic combat:

- Hitbox/hurtbox yang konsisten.
- Damage calculation.
- Attack cooldown.
- Dodge invulnerability window yang terukur.
- Hit reaction.
- Knockback jika sesuai.
- Death state.
- Loot drop.
- Feedback audio dan visual.
- Combat tidak boleh menghitung satu serangan berkali-kali tanpa alasan.

Implementasikan sekurangnya tiga tipe musuh yang benar-benar berbeda:

1. Slime — gerakan sederhana dan serangan jarak dekat.
2. Skeleton — tekanan jarak dekat dengan timing serangan berbeda.
3. Aether Wisp — mobilitas atau serangan jarak menengah.

Setiap tipe harus memiliki:

- State idle/patrol.
- Detection/aggro.
- Chase.
- Attack.
- Hurt.
- Death.
- Collision yang benar.
- Stat yang dapat dikonfigurasi.
- Loot yang sesuai.

Tambahkan minimal satu elite enemy atau boss pada vertical slice pertama.

Musuh harus benar-benar dapat menyerang, menerima damage, mati, dan menghasilkan loot. Jangan mengganti AI dengan sprite bergerak acak.

11. RPG PROGRESSION

Implementasikan:

- XP.
- Character level.
- Stat progression.
- Inventory.
- Equipment.
- Senjata dan armor.
- Consumable/healing items.
- Loot rarity jika sesuai.
- Currency atau sistem reward.
- Skill dan cooldown.
- Quest rewards.
- Item descriptions.
- Equipment comparison yang benar.
- Save/load progression.

Gunakan resource atau struktur data yang sesuai untuk definisi item, musuh, skill, dan quest.

Jangan menyimpan data definisi seluruh item sebagai kumpulan string tanpa validasi.

Periksa kapasitas inventory, item quantity, equipment slot, dan kondisi ketika inventory penuh.

12. NPC, QUEST, AND DIALOGUE

Dawnroot Valley harus memiliki NPC yang berfungsi.

Buat minimal tiga quest yang dapat diselesaikan:

1. Quest pengenalan dan interaksi dengan penduduk desa.
2. Quest eliminasi atau pengumpulan item dari area liar.
3. Quest dungeon yang menghasilkan reward nyata.

Setiap quest memiliki:

- ID stabil.
- Quest giver.
- Prasyarat.
- Objective.
- Progress tracking.
- Status available/active/completed.
- Reward.
- Penyimpanan status ke save file.
- UI penanda status.

NPC harus memiliki dialogue yang dapat ditampilkan dan sistem interaksi yang jelas.

Pastikan objective hanya meningkat karena aksi yang relevan. Menyerang musuh yang salah atau mengambil item yang tidak sesuai tidak boleh menyelesaikan quest secara keliru.

13. OPEN-WORLD ARCHITECTURE

Gunakan pendekatan open-world berbasis region dan chunk.

Jangan memuat seluruh konten akhir 2–3 GB ke memori sekaligus.

Arsitektur harus memungkinkan:

- Loading wilayah.
- Unloading wilayah yang tidak diperlukan.
- Transisi area.
- Penyimpanan state yang relevan.
- Region unlock.
- Discovery.
- Minimap.
- Checkpoint.
- Lokasi spawn.
- Quest dan encounter yang konsisten.
- Akses offline ke konten yang telah terpasang.

Jangan mengimplementasikan streaming tanpa kebutuhan nyata. Mulai dari sistem region yang sederhana, stabil, dan dapat diperluas.

Dawnroot Valley harus benar-benar bisa dieksplorasi dan memiliki konten. Jangan menyamakan peta besar kosong dengan open-world berkualitas.

14. INITIAL REGION — DAWNROOT VALLEY

Vertical slice pertama wajib memuat:

- Desa utama.
- Rumah atau bangunan yang dapat dimasuki atau dieksplorasi sesuai desain.
- NPC.
- Jalur ke hutan.
- Area encounter.
- Loot.
- Chest.
- Dungeon.
- Quest.
- Boss atau elite enemy.
- Reward yang dapat digunakan.
- Minimap.
- Pause menu.
- Save/load.
- Transisi wilayah.
- Tutorial yang tidak menghalangi gameplay.

Wilayah awal harus memiliki visual dan tujuan gameplay yang jelas.

Hindari area berisi tile tunggal yang diulang secara monoton tanpa variasi. Gunakan variasi dekorasi, bentuk jalur, objek lingkungan, elevasi visual, dan pencahayaan.

15. UI, HUD, AND MAP

Buat UI dengan hierarki visual yang jelas dan responsif.

HUD minimal:

- Health bar.
- Stamina bar.
- Level dan XP.
- Skill cooldown.
- Basic combat controls.
- Interact prompt.
- Quest tracker yang dapat diminimalkan.
- Minimap.
- Inventory.
- Equipment.
- Quest log.
- Dialogue panel.
- Settings.
- Pause menu.

Minimap menampilkan:

- Posisi pemain.
- NPC relevan.
- Quest objective.
- Titik penting yang sudah ditemukan.
- Jalur atau marker yang berguna.

Marker tidak boleh memenuhi seluruh minimap.

Semua panel harus mempunyai kondisi kosong, loading/error state yang sesuai, dan tampilan yang konsisten.

16. SAVE AND OFFLINE SYSTEM

Game single-player harus dapat dimainkan secara offline setelah game dan konten yang diperlukan terpasang.

Gunakan direktori data aplikasi seperti "user://" untuk penyimpanan.

Simpan data penting:

- Posisi karakter.
- Level dan XP.
- Progress karakter.
- Inventory.
- Equipment.
- Quest state.
- Region yang dibuka.
- Discovery.
- Checkpoint.
- Pengaturan gameplay yang diperlukan.

Implementasikan:

- Save manual.
- Autosave pada checkpoint atau peristiwa penting.
- Validasi data saat load.
- Penanganan save rusak.
- Fallback yang aman.
- Error handling ketika penyimpanan gagal.

Jangan menyimpan progres utama ke direktori source project atau mengandalkan file sementara dalam Downloads.

17. ASSET SIZE AND CONTENT DISTRIBUTION STRATEGY

Target distribusi awal:

- Usahakan paket awal yang siap dimainkan mencapai setidaknya 100 MB melalui aset dan konten nyata yang benar-benar digunakan.
- Catat ukuran APK dan aset secara terpisah.
- Jangan menghentikan implementasi hanya karena lima paket dasar berukuran kecil.
- Cari sumber tambahan yang legal dan sesuai dengan dunia Mythfall jika diperlukan.
- Bila target 100 MB belum tercapai, berikan ukuran aktual dan kekurangannya. Jangan menciptakan file dummy.

Target jangka panjang:
2–3 GB total konten game yang benar-benar tersedia dan digunakan.

Target tersebut merujuk pada keseluruhan konten setelah paket region tambahan terpasang, bukan kewajiban memasukkan semua konten ke satu APK.

Gunakan sistem content packs:

- Initial Pack — menu, karakter, Dawnroot Valley, UI, efek, dan audio awal.
- Emberfall Pack — lingkungan, karakter, musuh, dan konten Emberfall Highlands.
- Luminara Pack — lingkungan, NPC, dan konten Luminara Desert.
- Veilwood Pack — lingkungan, musuh, serta konten Veilwood Forest.
- Azure Pack — aset pesisir, pulau, dan Azure Shattercoast.
- Aether Crown Pack — konten endgame dan boss.

Paket tambahan harus membawa konten nyata yang dapat dimainkan atau digunakan.

Dilarang:

- Membuat file kosong untuk memperbesar ukuran.
- Menduplikasi file berkali-kali.
- Membuat data acak yang tidak digunakan.
- Mengganti ekstensi untuk memalsukan format.
- Menganggap jumlah tile identik sebagai konten dunia baru.
- Memasukkan arsip sumber yang tidak dibutuhkan ke APK tanpa alasan.

Buat manifest yang mencatat ukuran file sebenarnya, ukuran ekstrak, versi, isi paket, dan SHA-256.

Download manager harus:

- Menampilkan ukuran paket.
- Memeriksa ruang kosong.
- Menampilkan progres.
- Menangani kegagalan jaringan.
- Memverifikasi hash.
- Mencegah ekstraksi path berbahaya.
- Menyimpan konten di direktori data aplikasi yang tepat.
- Tidak mengunduh seluruh 2–3 GB secara otomatis.
- Memungkinkan pengguna memilih paket yang ingin dipasang.
- Memberi pesan yang jelas ketika paket tidak tersedia.
Jika seluruh target belum dapat dipenuhi dari sumber aset yang tersedia, laporkan kekurangannya dan siapkan tahapan ekspansi yang realistis. Jangan mengklaim konten sudah lengkap.

18. FILE STRUCTURE
Gunakan struktur modular yang masuk akal. Struktur berikut dapat disesuaikan jika dibutuhkan:
Scenes/
Boot/
MainMenu/
World/
Player/
Enemies/
NPC/
Dungeon/
UI/

Scripts/
Core/
Player/
Combat/
Enemies/
World/
NPC/
Quests/
Inventory/
Progression/
Save/
UI/
ContentPacks/

Assets/
Environment/
Characters/
Enemies/
NPC/
UI/
Audio/
VFX/
Fonts/


Data/
Items/
Enemies/
Quests/
Regions/

docs/ Tests/ Tools/ Build/ .github/workflows/

Pilih batas modul berdasarkan tanggung jawab dan kebutuhan nyata. Jangan membuat terlalu banyak abstraction layer tanpa manfaat.
Gunakan GDScript bertipe apabila sesuai. Gunakan signals untuk komunikasi antar sistem bila membantu mengurangi coupling. Gunakan resource atau data files untuk data yang perlu dikelola tanpa mengubah logika gameplay.
Pastikan semua path file sesuai dengan lokasi dan kapitalisasi sebenarnya.18. FILE STRUCTURE
Gunakan struktur modular yang masuk akal. Struktur berikut dapat disesuaikan jika dibutuhkan:

19. QUALITY ASSURANCE
Buat checklist pengujian dan jalankan sebanyak mungkin pemeriksaan yang benar-benar tersedia.
Periksa:
Validitas project.godot.
Referensi script.
Referensi scene.
Referensi texture dan audio.
Path resource.
Node path.
Signal connections.
Input actions.
Collision layers dan masks.
Landscape configuration.
Data save/load.
Item pickup.
Enemy damage/death.
Quest progress.
Dungeon completion.
Inventory boundaries.
Content manifest.
SHA-256 verification.
Android export configuration.
Jalankan headless validation hanya jika binary Godot yang cocok memang tersedia.
Jika tidak tersedia, lakukan inspeksi kode statis dan buat dokumentasi docs/ANDROID_TEST_PLAN.md yang dapat diikuti melalui Godot Editor Android.
Jangan menyatakan pengujian pada perangkat fisik sudah dilakukan sebelum benar-benar dijalankan.
Prioritaskan perbaikan error baru daripada mengulangi audit menyeluruh untuk hasil implementasi yang sudah dinyatakan berhasil, kecuali ada indikasi regresi.
20. APK BUILD AND INSTALLATION
Target distribusi utama adalah APK Android yang dapat dipasang dan dimainkan secara lokal.
Langkah:
Periksa kemampuan ekspor pada versi Godot Editor Android yang digunakan.
Siapkan export preset Android dengan application ID yang konsisten.
Pastikan orientasi landscape.
Jika editor dapat mengekspor APK, hasilkan build debug untuk pengujian.
Pasang dan jalankan build bila kemampuan perangkat mengizinkan.
Periksa apakah game dapat memulai permainan, menjalankan kontrol sentuh, dan menyimpan progres.
Jika ekspor langsung tidak tersedia atau gagal karena keterbatasan lingkungan, jangan mengklaim APK berhasil dibuat.
Siapkan GitHub Actions untuk membangun proyek GDScript menggunakan rilis Godot stabil dan export template yang cocok.
Pin versi engine dan template yang kompatibel.
Simpan APK sebagai artifact workflow dan lampirkan ke GitHub Release bila konfigurasi dan autentikasi memungkinkan.
Jangan mengasumsikan APK debug dari editor setara dengan rilis Google Play. Signing, release configuration, dan persyaratan distribusi harus ditangani terpisah.
Jangan menyimpan signing key, password, atau token di source code.

21. GITHUB AND SOURCE CONTROL
Nama repositori: Mythfall-Echoes-of-Aether
Jika tersedia autentikasi GitHub yang sah:
Verifikasi identitas dengan gh auth status.
Pastikan nama repository belum digunakan oleh proyek lain milik pengguna.
Buat repositori baru tanpa menimpa yang sudah ada.
Inisialisasi Git jika diperlukan.
Buat commit dengan pesan yang deskriptif.
Push source code yang siap dikembangkan.
Siapkan workflow validasi dan build Android.
Default repositori adalah public hanya jika pembuatan publik memang dapat dilakukan dengan aman dan tidak mengekspos data pribadi atau rahasia. Jangan pernah memasukkan credential atau data sensitif.
Buat .gitignore yang tepat untuk cache, file sementara, artefak build, log, file pribadi, dan secret.
Jangan mengunggah file besar ke Git biasa jika melampaui batas yang berlaku.
Gunakan GitHub Releases untuk APK dan content packs besar. Pecah arsip menjadi beberapa paket logis dengan ukuran setiap file di bawah batas per-file yang berlaku. Jangan menyertakan semua aset 2–3 GB dalam riwayat Git.
Buat:
README.md
CHANGELOG.md
LICENSE
ASSET_CREDITS.md
docs/ARCHITECTURE.md
docs/ANDROID_BUILD.md
docs/CONTENT_PACKS.md
docs/ANDROID_TEST_PLAN.md
.gitignore
.github/workflows/
Jika autentikasi GitHub tidak tersedia, selesaikan pekerjaan lokal terlebih dahulu. Laporkan langkah autentikasi manual secara spesifik. Jangan mengarang nama URL repo, commit, atau status push.
22. IMPLEMENTATION PHASES
Laksanakan pekerjaan secara bertahap.
Phase A — Project Foundation
Periksa workspace.
Buat konfigurasi proyek Godot 4 GDScript.
Buat scene boot dan scene utama.
Konfigurasikan Android landscape.
Buat struktur direktori.
Siapkan dokumentasi.
Mulai mengunduh dan mengintegrasikan lima paket aset resmi.
Pastikan scene utama memiliki jalur masuk gameplay.
Phase B — Playable Vertical Slice
Implementasikan player.
Implementasikan kamera.
Implementasikan kontrol layar sentuh.
Integrasikan aset lingkungan awal.
Implementasikan Dawnroot Valley.
Implementasikan tiga tipe musuh.
Implementasikan combat.
Implementasikan loot, item, dan progression.
Implementasikan NPC dan tiga quest.
Implementasikan dungeon.
Implementasikan UI, minimap, dan pause menu.
Implementasikan save/load.
Implementasikan audio dan efek visual.
Validasi gameplay utama.
Phase C — Android Verification
Buka proyek pada Godot Editor Android.
Perbaiki masalah import dan konfigurasi.
Jalankan scene utama.
Periksa error yang ditemukan.
Uji landscape.
Uji kontrol sentuh.
Uji quest, combat, dungeon, dan save/load.
Ekspor APK melalui editor jika didukung.
Jika perlu, gunakan workflow GitHub Actions.
Catat hasil pengujian dan ukuran build aktual.
Phase D — Expansion Architecture
Implementasikan region management.
Implementasikan content pack manifest.
Implementasikan download dan verifikasi paket.
Implementasikan penyimpanan konten terpasang.
Siapkan pipeline untuk region lanjutan.
Tambahkan konten tambahan sesuai kemampuan produksi dan sumber aset.
Phase E — GitHub Release
Siapkan repository.
Buat commit.
Push source code.
Validasi workflow.
Build APK bila toolchain tersedia.
Upload artifact atau Release jika berhasil.
Dokumentasikan versi, ukuran, dan isi paket.

23. EXECUTION RULES
Mulai dengan memeriksa workspace.
Langsung lakukan implementasi, jangan berhenti pada perencanaan.
Jangan menunggu saya menyetujui setiap detail desain yang wajar.
Jangan menghapus file di luar proyek.
Jangan meminta saya menyalin kode satu file demi satu file secara manual jika OpenCode dapat membuat file tersebut langsung.
Jangan mengubah lokasi proyek tanpa alasan teknis dan tanpa melaporkannya.
Jangan mengarang hasil terminal.
Jangan menyebut fitur selesai sebelum ada bukti implementasi.
Jika akses web atau download gagal, lanjutkan pekerjaan lain yang tidak terblokir.
Jika sebuah fitur terlalu besar untuk satu iterasi, implementasikan bagian inti yang dapat digunakan dan jelaskan batasannya.
Jika ditemukan error, perbaiki error yang relevan sebelum menambahkan kompleksitas lebih lanjut.
Jangan menggunakan file placeholder kosong untuk mengklaim sebuah fitur ada.
Jangan menambahkan fitur online, multiplayer, login wajib, atau server backend yang tidak diperlukan.
Fokus pada game single-player offline.
Jangan melakukan audit penuh berulang kali jika tahap sebelumnya sudah selesai dengan baik dan tidak ada masalah baru.
Utamakan kualitas implementasi, keterpeliharaan kode, stabilitas Android, dan gameplay yang benar-benar berjalan.
24. REQUIRED FINAL REPORT
Setelah iterasi implementasi selesai, berikan laporan faktual:
Lokasi absolut proyek.
Versi Godot yang ditargetkan.
Status proyek saat ini.
Struktur direktori yang dibuat.
Fitur yang benar-benar sudah berfungsi.
Paket aset yang benar-benar berhasil diunduh dan digunakan.
Lisensi dan sumber aset.
Ukuran source project dan aset aktual.
Ukuran APK apabila benar-benar tersedia.
Hasil validasi serta error yang masih tersisa.
Apakah APK berhasil diekspor dan diuji.
Nama serta URL repositori GitHub jika benar-benar tersedia.
Status commit dan push.
Region serta fitur yang belum selesai.
Selisih dari target konten awal 100 MB.
Status terhadap target konten final 2–3 GB.
Langkah teknis selanjutnya yang konkret.
Mulai sekarang dari pemeriksaan workspace dan implementasikan Phase A serta Phase B. Jangan berhenti pada proposal atau dokumentasi. Sasaran iterasi pertama adalah fondasi Godot yang valid dan vertical slice Dawnroot Valley yang dapat dimainkan di Android landscape.
