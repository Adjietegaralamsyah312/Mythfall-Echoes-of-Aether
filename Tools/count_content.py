#!/usr/bin/env python3
"""BULK-001 hitung konten nyata (tanpa dep). Dedup SHA-256 isi file
(format/salinan sama = sekali) + cache inode; pack audio (MusicLibrary)
terhitung via res://Assets. ponytail: sha256 stdlib; upgrade path du -sb."""
import hashlib
import json, os, re, sys

_SHA_CACHE = {}
DEDUP_SKIPPED = 0

def _fkey(fp):
    """Kunci dedup = sha256 isi (cache per inode+size+mtime)."""
    global DEDUP_SKIPPED
    try:
        st = os.stat(fp)
    except OSError:
        return None
    ck = (st.st_ino, st.st_size, st.st_mtime_ns)
    hit = _SHA_CACHE.get(ck)
    if hit is not None:
        return hit
    h = hashlib.sha256()
    try:
        with open(fp, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
    except OSError:
        return None
    key = "sha256:" + h.hexdigest()
    _SHA_CACHE[ck] = key
    return key

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) if os.path.dirname(os.path.abspath(__file__)).endswith("Tools") else os.getcwd()
if os.path.basename(ROOT) == "Tools":
    ROOT = os.path.dirname(ROOT)
TARGET = 100_000_000

def res_to_disk(p):
    return os.path.join(ROOT, p[len("res://"):].replace("/", os.sep)) if p.startswith("res://") else None

def parse_contents(tres):
    txt = open(tres, encoding="utf-8", errors="ignore").read()
    m = re.search(r"contents\s*=\s*Array\[String\]\(\[(.*?)\]\)", txt, re.S)
    if not m:
        return []
    return re.findall(r'"([^"]+)"', m.group(1))

def parse_field(tres, field):
    txt = open(tres, encoding="utf-8", errors="ignore").read()
    m = re.search(r"%s\s*=\s*(-?\d+|\"[^\"]*\")" % field, txt)
    if not m:
        return None
    v = m.group(1)
    return int(v) if re.match(r"-?\d+$", v) else v.strip('"')

def walk_bytes(paths, seen):
    global DEDUP_SKIPPED
    total = 0
    for p in paths:
        d = res_to_disk(p)
        if not d or not os.path.exists(d):
            continue
        if os.path.isfile(d):
            for extra in [d, d + ".import", d + ".uid"]:
                if os.path.isfile(extra):
                    key = _fkey(extra)
                    if key is None:
                        continue
                    if key not in seen:
                        seen.add(key)
                        total += os.path.getsize(extra)
                    else:
                        DEDUP_SKIPPED += os.path.getsize(extra)
        else:
            for dp, _, fns in os.walk(d):
                for fn in fns:
                    fp = os.path.join(dp, fn)
                    key = _fkey(fp)
                    if key is None:
                        continue
                    if key not in seen:
                        seen.add(key)
                        try:
                            total += os.path.getsize(fp)
                        except OSError:
                            pass
                    else:
                        try:
                            DEDUP_SKIPPED += os.path.getsize(fp)
                        except OSError:
                            pass
    return total

def dir_bytes(path):
    t, seen = 0, set()
    if not os.path.exists(path):
        return 0
    for dp, _, fns in os.walk(path):
        for fn in fns:
            fp = os.path.join(dp, fn)
            key = _fkey(fp)
            if key is None:
                continue
            if key not in seen:
                seen.add(key)
                try:
                    t += os.path.getsize(fp)
                except OSError:
                    pass
    return t

def main():
    packs = ["initial", "emberfall", "luminara", "veilwood", "azure", "aether_crown"]
    per, unionset, unionbytes = {}, set(), 0
    for pid in packs:
        tres = os.path.join(ROOT, "Data", "Packs", pid + ".tres")
        contents = parse_contents(tres) if os.path.exists(tres) else []
        seen = set()
        b = walk_bytes(contents, seen)
        per[pid] = (b, len(contents))
        for ino in seen:
            unionset.add(ino)
    # union ulang agar double-count antar-paket hilang
    useen = set()
    unionbytes = 0
    for pid in packs:
        tres = os.path.join(ROOT, "Data", "Packs", pid + ".tres")
        contents = parse_contents(tres) if os.path.exists(tres) else []
        unionbytes += walk_bytes(contents, useen)
    ekspansi = per.get("emberfall", (0, 0))[0]
    print("pack            bytes  entries")
    for pid in packs:
        print("%-14s %7d  %d" % (pid, per[pid][0], per[pid][1]))
    print("total_runtime_union %d" % unionbytes)
    print("ekspansi_siap(emberfall) %d" % ekspansi)
    # arsip Sources (staging, BUKAN konten)
    print("sources_staging %d (tidak dihitung konten)" % dir_bytes(os.path.join(ROOT, "Sources")))
    for d in ["docs", ".git", ".godot"]:
        print("%-14s %d" % (d, dir_bytes(os.path.join(ROOT, d))))
    apk = 0
    bd = os.path.join(ROOT, "Build")
    if os.path.isdir(bd):
        for fn in os.listdir(bd):
            if fn.endswith((".apk", ".aab")):
                apk += os.path.getsize(os.path.join(bd, fn))
    print("apk_build %d" % apk)
    # zip arsip per paket dari manifest bila ada
    try:
        mj = json.load(open(os.path.join(ROOT, "ASSET_MANIFEST.json")))
        for a in mj.get("assets", []):
            print("zip %-28s %d" % (a.get("path", "?"), a.get("zip_bytes", 0)))
    except Exception as e:
        print("manifest_baca_gagal %s" % e)
    print("TARGET %d" % TARGET)
    print("TOTAL_KONTEN %d" % unionbytes)
    print("DEDUP_SHA256_SKIPPED %d (byte duplikat isi, tidak dihitung)" % DEDUP_SKIPPED)
    print("SELISIH %d (kurang)" % (TARGET - unionbytes) if unionbytes < TARGET else "LEBIH %d" % (unionbytes - TARGET))

if __name__ == "__main__":
    main()
