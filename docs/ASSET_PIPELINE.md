# ASSET PIPELINE — Phase A

Prosedur unduh 5 paket Kenney (berhasil semua, 2026-10-13):

1. Buka halaman resmi paket (`https://kenney.nl/assets/<slug>`).
2. Verifikasi tulisan "CC0 licensed" di halaman.
3. Resolve link unduhan dari HTML halaman (tombol Download → modal
   `#inline-download` → `href` `.zip` di `kenney.nl/media/...`).
   URL zip TIDAK dikarang — diekstrak dari halaman via `grep`.
4. Unduh via `curl -sL`, verifikasi integritas `unzip -t` (5/5 OK).
5. Ekstrak ke `Assets/...`, salin `License.txt` asli ke `LICENSES/`.
6. Catat ukuran + sha256 di `ASSET_MANIFEST.json`.

Unduhan manual (jika pipeline diulang): buka tiap URL di
`ASSET_CREDITS.md`, klik Download → "Continue without donating".

Catatan: file `.url` bawaan Kenney (Donate/Facebook/Visit) ikut
terekstrak apa adanya; boleh dihapus saat bersih-bersih Phase B.
Impor `.import` Godot dibuat saat proyek dibuka di editor.
