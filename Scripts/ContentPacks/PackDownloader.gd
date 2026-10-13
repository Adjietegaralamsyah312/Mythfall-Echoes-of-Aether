class_name PackDownloader
extends Node
## D2 unduh manual per paket: cek status -> cek ukuran -> HTTP (progres,
## timeout + retry 1x + cancel) -> verifikasi SHA-256 -> ekstrak aman
## (tolak zip-slip) ke user://content_packs/<pack_id>/ -> catat registry.
## Bahasa Indonesia; gagal selalu jujur via download_failed.
## Keputusan ruang disk: Godot tak punya API ruang kosong portabel, jadi
## file_bytes -1 (tak diketahui) DITOLAK; selebihnya tulis + gagal jujur.
## sha256 kosong DITOLAK (jangan instal tanpa verifikasi).
# ponytail: 1 HTTPRequest + polling _process; upgrade path resume bila perlu.

signal download_progress(pack_id: String, downloaded: int, total: int)
signal download_finished(pack_id: String)
signal download_failed(pack_id: String, reason: String)

const STORE_DIR: String = "user://content_packs"

var registry: PackRegistry
var installed: InstalledRegistry
var timeout_sec: float = 30.0
var last_error: String = ""

var _http: HTTPRequest
var _def: PackDef
var _downloading: bool = false
var _tries_left: int = 0
var _tmp: String = ""
var _expected: int = 0
var _last_sent: int = -1


func _ready() -> void:
	_ensure_http()


func setup(reg: PackRegistry, inst: InstalledRegistry) -> void:
	registry = reg
	installed = inst


## "" = boleh; selain itu alasan Indonesia (jujur, tampilkan ke user).
func can_download(pid: String) -> String:
	if pid.is_empty() or "/" in pid or ".." in pid:
		return "ID paket tak valid."
	if registry == null:
		return "Registry paket belum siap."
	var p: PackDef = registry.get_pack(pid)
	if p == null:
		return "Paket tak dikenal: %s." % pid
	return can_download_def(p)


func can_download_def(p: PackDef) -> String:
	if registry != null and registry.is_built_in(p.pack_id):
		return "Paket bawaan — sudah termasuk instalasi."
	if p.status == PackDef.Status.BUILT_IN:
		return "Paket bawaan — sudah termasuk instalasi."
	if p.status == PackDef.Status.UNAVAILABLE:
		return "Paket belum tersedia — konten belum ada."
	if p.download_url.strip_edges().is_empty():
		return "Tautan unduh belum tersedia."
	if p.file_bytes < 0:
		return "Ukuran unduhan belum diketahui — unduh ditolak."
	if p.sha256.strip_edges().is_empty():
		return "Hash belum tersedia — unduh ditolak demi keamanan."
	return ""


func start(pid: String) -> int:
	if registry == null:
		return _reject(pid, "Registry paket belum siap.")
	var p: PackDef = registry.get_pack(pid)
	if p == null:
		return _reject(pid, "Paket tak dikenal: %s." % pid)
	return start_with_def(p)


## Jalur uji: definisi in-memory (tanpa ubah manifest D1).
func start_with_def(p: PackDef) -> int:
	var why: String = can_download_def(p)
	if not why.is_empty():
		return _reject(p.pack_id, why)
	if _downloading:
		return _reject(p.pack_id, "Unduhan lain sedang berjalan.")
	_ensure_http()
	_def = p
	_tmp = STORE_DIR + "/" + p.pack_id + ".zip.part"
	_expected = p.file_bytes
	_tries_left = 1
	_downloading = true
	_last_sent = -1
	if not is_inside_tree():
		_begin_request.call_deferred()
	else:
		_begin_request()
	return OK


func cancel() -> void:
	if not _downloading:
		return
	_downloading = false
	if _http != null:
		_http.cancel_request()
	_cleanup_tmp()
	var pid: String = _def.pack_id if _def != null else ""
	_def = null
	last_error = "Unduhan dibatalkan."
	download_failed.emit(pid, last_error)


func is_downloading() -> bool:
	return _downloading


static func verify_sha256(file_path: String, expected: String) -> bool:
	if expected.strip_edges().is_empty():
		return false
	if not FileAccess.file_exists(file_path):
		return false
	var actual: String = FileAccess.get_sha256(file_path).to_lower()
	return actual == expected.strip_edges().to_lower()


## Tolak zip-slip: "..", absolute, drive letter. True = aman.
static func is_entry_safe(entry: String) -> bool:
	if entry.is_empty():
		return false
	var e: String = entry.replace("\\", "/")
	if e.begins_with("/") or e.contains(":"):
		return false
	var trimmed: String = e.trim_suffix("/")
	if trimmed.is_empty():
		return false
	for part: String in trimmed.split("/"):
		if part in ["", ".", ".."]:
			return false
	return true


## "" = OK; selain itu pesan Indonesia. Pra-pindai semua entri dulu:
## satu entri berbahaya -> TOLAK SELURUH arsip tanpa ekstrak apa pun.
static func extract_zip(zip_path: String, dest_dir: String) -> String:
	var z := ZIPReader.new()
	if z.open(zip_path) != OK:
		return "Arsip tak bisa dibuka."
	var files: PackedStringArray = z.get_files()
	for f: String in files:
		if not is_entry_safe(f):
			z.close()
			return "Paket ditolak: ada entri path berbahaya (%s)." % f
	var mk: int = DirAccess.make_dir_recursive_absolute(dest_dir)
	if mk != OK:
		z.close()
		return "Tak bisa membuat folder tujuan."
	for f: String in files:
		if f.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(dest_dir + "/" + f.trim_suffix("/"))
			continue
		var data: PackedByteArray = z.read_file(f)
		var out: String = dest_dir + "/" + f
		DirAccess.make_dir_recursive_absolute(out.get_base_dir())
		var w: FileAccess = FileAccess.open(out, FileAccess.WRITE)
		if w == null:
			z.close()
			return "Gagal menulis %s." % f
		w.store_buffer(data)
		w.close()
	z.close()
	return ""


static func format_bytes(b: int) -> String:
	if b < 0:
		return "belum diketahui"
	if b == 0:
		return "bawaan"
	if b < 1024:
		return "%d B" % b
	if b < 1048576:
		return "%.1f KB" % (float(b) / 1024.0)
	return "%.1f MB" % (float(b) / 1048576.0)


func _process(_delta: float) -> void:
	if not _downloading or _http == null or _def == null:
		return
	var got: int = _http.get_downloaded_bytes()
	var total: int = _http.get_body_size()
	if total <= 0:
		total = _expected
	_emit_progress(_def.pack_id, got, total)


func _ensure_http() -> void:
	if _http != null:
		return
	_http = HTTPRequest.new()
	_http.timeout = timeout_sec
	add_child(_http)
	_http.request_completed.connect(_on_completed)


func _begin_request() -> void:
	_http.timeout = timeout_sec
	DirAccess.make_dir_recursive_absolute(STORE_DIR)
	_http.download_file = _tmp
	_emit_progress(_def.pack_id, 0, _expected)
	var err: int = _http.request(_def.download_url)
	if err != OK:
		_fail_now("Gagal memulai unduhan (err %d)." % err)


func _on_completed(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if not _downloading or _def == null:
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		if _tries_left > 0:
			_tries_left -= 1
			_begin_request()
			return
		_fail_now(_net_reason(result))
		return
	if code != 200:
		_fail_now("Server menjawab %d. Tautan mungkin kedaluwarsa." % code)
		return
	_emit_progress(_def.pack_id, _expected, _expected)
	if not FileAccess.file_exists(_tmp):
		_fail_now("File unduhan hilang.")
		return
	if not verify_sha256(_tmp, _def.sha256):
		_cleanup_tmp()
		_fail_now("Hash SHA-256 tak cocok — file dihapus demi keamanan.")
		return
	var dest: String = STORE_DIR + "/" + _def.pack_id
	var ex: String = extract_zip(_tmp, dest)
	_cleanup_tmp()
	if not ex.is_empty():
		_fail_now(ex)
		return
	var pid: String = _def.pack_id
	var ver: String = _def.version
	_downloading = false
	_def = null
	if installed != null:
		installed.mark_installed(pid, ver, _expected)
	download_finished.emit(pid)


func _net_reason(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CONNECTION_ERROR, HTTPRequest.RESULT_NO_RESPONSE:
			return "Gagal jaringan: tak bisa terhubung. Periksa internet Anda."
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "Gagal jaringan: alamat server tak dikenal."
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "Gagal jaringan: koneksi aman (TLS) ditolak."
		HTTPRequest.RESULT_TIMEOUT:
			return "Waktu habis: server tak merespons."
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN, HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return "Gagal menyimpan file: penyimpanan penuh atau terkunci."
		_:
			return "Unduhan gagal (kode %d)." % result


func _reject(pid: String, reason: String) -> int:
	last_error = reason
	download_failed.emit(pid, reason)
	return ERR_UNAVAILABLE


func _fail_now(reason: String) -> void:
	var pid: String = _def.pack_id if _def != null else ""
	_downloading = false
	_def = null
	_cleanup_tmp()
	last_error = reason
	download_failed.emit(pid, reason)


func _emit_progress(pid: String, got: int, total: int) -> void:
	if got == _last_sent and total > 0:
		return
	_last_sent = got
	download_progress.emit(pid, got, total)


func _cleanup_tmp() -> void:
	if not _tmp.is_empty() and FileAccess.file_exists(_tmp):
		DirAccess.remove_absolute(_tmp)
