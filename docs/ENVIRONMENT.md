# ENVIRONMENT — Mythfall: Echoes of Aether (Phase A)

- Engine: **Godot 4.7.2.stable.termux** (`godot --version`).
- Renderer: **gl_compatibility** (`rendering/renderer/rendering_method` +
  `rendering_method.mobile`). Alasan: aman di GPU Android & Godot Editor
  Android; hindari Forward+ sebagai default di perangkat target.
- Target: **Android, landscape-only**
  (`display/window/handheld/orientation=4` = sensor landscape),
  viewport 1280×720, stretch `canvas_items`, aspect `expand`.
- Bahasa: GDScript typed, tanpa C#.
- Autoload: tidak ada (belum perlu di Phase A).

## Buka di Godot Editor Android

1. Salin/import folder `Mythfall_Echoes_of_Aether` ke penyimpanan perangkat.
2. Godot Editor Android → Import → pilih `project.godot` → Import & Edit.
3. Jalankan scene utama (Boot → MainMenu). Boot tanpa splash panjang
   (`boot_splash/show_image=false`).
4. Untuk kembali dari world placeholder tekan Esc / tombol kembali
   (action `ui_cancel`).

## Headless via Termux

```sh
godot --version
godot --headless --path "/storage/emulated/0/Download/Mythfall_Echoes_of_Aether" --import
```

Catatan: `--import` mengimpor resource & keluar. Jika versi CLI berbeda,
lakukan import ulang dari Godot Editor Android.
