Lanjutkan Phase C + Phase E sekarang untuk proyek Mythfall: Echoes of Aether.

Workspace:
"/storage/emulated/0/Download/Mythfall_Echoes_of_Aether"

Akun GitHub yang sudah login menurut pemeriksaan sebelumnya:
"Adjietegaralamsyah312"

KONTEKS:

- Phase A dan B telah selesai menurut laporan sebelumnya.
- Godot 4.7.2.stable.termux tersedia.
- Proyek menggunakan GDScript, bukan C#.
- Renderer: gl_compatibility.
- Source dan aset saat ini sekitar 14 MB.
- Validasi headless dan test yang dilaporkan sebelumnya lulus.
- APK belum dibuat.
- Godot Editor Android belum diuji secara manual oleh pengguna.

Jangan mengulang implementasi Phase A/B, jangan mengganti arsitektur tanpa alasan teknis, dan jangan mengulang audit penuh tanpa menemukan masalah baru. Pertahankan gameplay yang sudah ada.

TASK 1 — SAFETY CHECKPOINT

1. Verifikasi direktori kerja dan status Git.
2. Jangan menghapus atau menimpa file proyek yang ada.
3. Periksa ".gitignore", lisensi aset, file sensitif, token, konfigurasi lokal, dan signing keys.
4. Pastikan cache generated Godot tidak dimasukkan ke repositori.
5. Jika Git belum diinisialisasi, siapkan checkpoint commit setelah pemeriksaan dasar.
6. Jangan mengubah konfigurasi Git global.
7. Jangan mengarang hasil command atau hasil build.

TASK 2 — PHASE C: ANDROID EXPORT

Siapkan proyek untuk menghasilkan APK Android debug yang dapat diuji.

- Target engine: Godot 4.7.2 stable.
- Gunakan GDScript dan renderer yang sudah dipakai proyek.
- Jangan mengupgrade engine secara otomatis.
- Gunakan package ID "com.mythfall.echoesofaether".
- Target Android ARM64 jika didukung oleh konfigurasi ekspor yang dipilih.
- Pastikan landscape-only dan pengaturan mobile yang diperlukan tetap konsisten.
- Gunakan nama preset Android yang jelas dan konsisten.
- Jangan membuat konfigurasi yang merusak proyek yang sudah dapat dijalankan.
- Jangan memasukkan credential atau signing key ke repositori.

Buat atau perbaiki "export_presets.cfg" sesuai format yang valid untuk versi engine. Periksa referensi pengaturan ekspor melalui dokumentasi resmi dan file konfigurasi yang tersedia. Jangan mengarang nama opsi export yang belum diverifikasi.

Jika ekspor melalui Godot Editor Android tersedia, dokumentasikan langkah tepat untuk menghasilkan APK debug dari editor.

Jika ekspor dari lingkungan tersebut tidak dapat dilakukan secara otomatis, lanjutkan dengan workflow CI dan dokumentasikan hambatan sebenarnya.

TASK 3 — GITHUB ACTIONS

Buat workflow:

".github/workflows/android-debug-apk.yml"

Workflow harus:

1. Berjalan pada runner Linux GitHub Actions.
2. Menggunakan Godot 4.7.2 stable dengan versi yang dipatok secara eksplisit.
3. Menggunakan export template yang cocok dengan versi engine tersebut.
4. Memverifikasi download atau checksum engine/template jika tersedia.
5. Menyiapkan komponen Android yang benar-benar diperlukan oleh metode build.
6. Melakukan import resource dan validasi headless.
7. Mengekspor preset Android dengan nama yang sesuai dengan "export_presets.cfg".
8. Menyimpan APK debug sebagai artifact GitHub Actions.
9. Gagal secara eksplisit jika import, export, atau pemeriksaan file APK gagal.
10. Melaporkan ukuran APK aktual dan commit SHA yang sedang dibangun.

Gunakan metode instalasi engine dan export template yang didukung dokumentasi resmi. Jangan menggunakan tautan download yang ditebak, versi floating yang berubah tanpa sengaja, atau workflow palsu yang hanya membuat file APK kosong.

Gunakan toolchain yang sesuai untuk Godot 4.7.2 stable. Jangan mengasumsikan engine Termux harus bisa dijalankan langsung di runner Linux; gunakan binary resmi yang sesuai untuk runner tersebut.

Bangun workflow release terpisah hanya jika benar-benar diperlukan. Untuk tahap ini, prioritaskan debug APK artifact yang berhasil dibuat.

TASK 4 — PHASE E: GITHUB REPOSITORY

Nama repository:
"Mythfall-Echoes-of-Aether"

1. Jalankan "gh auth status".
2. Verifikasi akun GitHub yang sedang aktif.
3. Periksa apakah repository tersebut sudah ada sebelum membuatnya.
4. Jangan pernah menimpa repository yang tidak terkait.
5. Jika repository belum ada, buat repository baru dan push source code serta workflow.
6. Repository boleh dibuat public setelah pemeriksaan memastikan tidak ada secret, data pribadi, atau file yang tidak layak dipublikasikan.
7. Jika ada risiko keamanan atau kepemilikan, jangan melakukan push yang berisiko; laporkan masalah spesifiknya.
8. Pastikan aset yang disertakan dapat didistribusikan sesuai lisensinya.
9. Pertahankan "ASSET_CREDITS.md", "ASSET_MANIFEST.json", dokumentasi, dan folder lisensi.
10. Jangan memasukkan cache engine, folder ".godot/", kredensial, atau signing key ke Git.
11. Jangan memasukkan APK berukuran besar ke riwayat Git jika lebih sesuai disimpan sebagai Actions artifact atau GitHub Release.
12. Buat commit dengan pesan yang menjelaskan perubahan nyata dan push ke remote yang benar.

TASK 5 — VALIDATION

Setelah implementasi:

- Validasi struktur workflow.
- Validasi preset Android sejauh kemampuan tool tersedia.
- Jalankan pemeriksaan engine yang tersedia tanpa mengklaim pengujian yang belum dijalankan.
- Periksa konfigurasi landscape dan package ID.
- Periksa keberhasilan CI dengan status run yang sebenarnya.
- Jika build berhasil, verifikasi APK benar-benar ada, ukuran file masuk akal, dan artifact tersedia.
- Jika build gagal, baca log, perbaiki penyebab yang jelas, lalu jalankan ulang.
- Jangan mengklaim APK berhasil dipasang atau dimainkan di perangkat fisik jika belum diuji.
- Jangan mengklaim seluruh game sudah siap dirilis hanya karena ekspor APK berhasil.

Jangan memublikasikan GitHub Release final sebelum APK melewati pemeriksaan yang diperlukan.

BATAS SCOPE

Fokus hanya pada Phase C dan Phase E:

- konfigurasi ekspor Android,
- APK debug,
- GitHub Actions,
- repository,
- commit dan push,
- dokumentasi build.

Jangan mulai Phase D atau menambahkan region baru pada tahap ini. Jangan mengejar target 100 MB dengan file dummy. Pertahankan ukuran aktual dan integritas proyek.

Setelah selesai, berikan laporan:

1. Lokasi proyek.
2. Nama dan URL repository yang benar-benar tersedia.
3. Commit SHA dan status push.
4. Lokasi export preset.
5. Nama workflow CI.
6. Status build dan log error jika gagal.
7. Ukuran APK aktual jika berhasil.
8. Link artifact atau Release hanya jika benar-benar tersedia.
9. Hal yang belum diuji di Godot Editor Android atau perangkat fisik.

Mulai sekarang dan tuntaskan pekerjaan yang dapat dilakukan dalam sesi ini. Jangan berhenti hanya pada rencana atau dokumentasi.
