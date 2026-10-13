class_name PackDef
extends Resource
## D1 manifest satu content pack (dibaca PackRegistry; kontrak beku untuk D2).
## Aturan jujur: UNAVAILABLE = konten belum ada (ukuran -1, url/sha kosong).
# ponytail: Resource polos tanpa logika unduh; unduh/verifikasi/instal = D2.

enum Status { BUILT_IN, AVAILABLE, UNAVAILABLE }

@export var pack_id: String = ""
@export var display_name: String = ""
@export var version: String = "1.0.0"
@export var schema_version: int = 1
@export var status: int = Status.UNAVAILABLE
@export var region_ids: Array[String] = []
@export var download_url: String = ""
## Ukuran file unduhan; BUILT_IN = 0 (ikut instalasi); belum diketahui = -1.
@export var file_bytes: int = -1
## Ukuran terpasang di disk (hasil du); belum ada konten = -1.
@export var installed_bytes: int = -1
@export var sha256: String = ""
## res:// path nyata; hanya initial yang mengisi (paket lain: kosong).
@export var contents: Array[String] = []
@export var min_app_version: String = "0.1.0"
@export var description: String = ""
@export var dependencies: Array[String] = []
@export var license_note: String = ""
