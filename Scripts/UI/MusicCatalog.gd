class_name MusicCatalog
extends RefCounted
## BULK-001 katalog soundtrack pemain (SATU sistem musik: data di sini,
## playback di AudioManager.play_music — jangan sistem player kedua).
## 16 trek CC0: 8 WAV drakzlin (music-loops-0) + 8 MP3 troubadour
## (fantasy-song-pack-volume-1). File di Assets/Audio/MusicLibrary/.
## Auto-BGM hanya trek cocok (fantasy -> menu/valley/luminara);
## battle/dark/chiptune = katalog opsional SAJA (jangan EDM ke region).
# ponytail: Array Dictionary statis; upgrade path Resource .tres bila >50 trek.

const LIB_BASE: String = "res://Assets/Audio/MusicLibrary/"

const TRACKS: Array[Dictionary] = [
	{"id": "wandering_woodlands", "title": "Wandering Woodlands", "category": "fantasy", "file": "wandering_woodlands.mp3", "creator": "troubadour", "source": "https://opengameart.org/content/fantasy-song-pack-volume-1", "license": "CC0", "use": ["menu", "valley"]},
	{"id": "back_to_nature", "title": "Back to Nature", "category": "fantasy", "file": "back_to_nature.mp3", "creator": "troubadour", "source": "https://opengameart.org/content/fantasy-song-pack-volume-1", "license": "CC0", "use": ["valley", "menu"]},
	{"id": "homestead", "title": "Homestead", "category": "fantasy", "file": "homestead.mp3", "creator": "troubadour", "source": "https://opengameart.org/content/fantasy-song-pack-volume-1", "license": "CC0", "use": ["luminara", "valley"]},
	{"id": "jaunt", "title": "Jaunt", "category": "fantasy", "file": "jaunt.mp3", "creator": "troubadour", "source": "https://opengameart.org/content/fantasy-song-pack-volume-1", "license": "CC0", "use": ["luminara", "valley"]},
	{"id": "fairy_lights", "title": "Fairy Lights", "category": "fantasy", "file": "fairy_lights.mp3", "creator": "troubadour", "source": "https://opengameart.org/content/fantasy-song-pack-volume-1", "license": "CC0", "use": ["valley", "menu"]},
	{"id": "springly_sprigs", "title": "Springly Sprigs", "category": "fantasy", "file": "springly_sprigs.mp3", "creator": "troubadour", "source": "https://opengameart.org/content/fantasy-song-pack-volume-1", "license": "CC0", "use": ["valley"]},
	{"id": "snow_day", "title": "Snow Day", "category": "fantasy", "file": "snow_day.mp3", "creator": "troubadour", "source": "https://opengameart.org/content/fantasy-song-pack-volume-1", "license": "CC0", "use": ["menu"]},
	{"id": "bells_of_winter", "title": "Bells of Winter", "category": "fantasy", "file": "bells_of_winter.mp3", "creator": "troubadour", "source": "https://opengameart.org/content/fantasy-song-pack-volume-1", "license": "CC0", "use": ["menu"]},
	{"id": "battle", "title": "Battle Loop", "category": "battle", "file": "Battle.wav", "creator": "drakzlin", "source": "https://opengameart.org/content/music-loops-0", "license": "CC0", "use": ["combat"]},
	{"id": "action_a", "title": "Action A", "category": "battle", "file": "Action_A.wav", "creator": "drakzlin", "source": "https://opengameart.org/content/music-loops-0", "license": "CC0", "use": ["combat", "boss"]},
	{"id": "action_b", "title": "Action B", "category": "battle", "file": "Action_B.wav", "creator": "drakzlin", "source": "https://opengameart.org/content/music-loops-0", "license": "CC0", "use": ["boss", "combat"]},
	{"id": "horror", "title": "Horror Drone", "category": "dark", "file": "Horror.wav", "creator": "drakzlin", "source": "https://opengameart.org/content/music-loops-0", "license": "CC0", "use": ["crypt", "boss"]},
	{"id": "horror_b", "title": "Horror B", "category": "dark", "file": "Horror_B.wav", "creator": "drakzlin", "source": "https://opengameart.org/content/music-loops-0", "license": "CC0", "use": ["crypt", "boss"]},
	{"id": "chiptune_1b2", "title": "Chiptune 1B2", "category": "chiptune", "file": "chiptune_1B2.wav", "creator": "drakzlin", "source": "https://opengameart.org/content/music-loops-0", "license": "CC0", "use": ["optional"]},
	{"id": "chiptune_1c2", "title": "Chiptune 1C2", "category": "chiptune", "file": "chiptune_1C2.wav", "creator": "drakzlin", "source": "https://opengameart.org/content/music-loops-0", "license": "CC0", "use": ["optional"]},
	{"id": "chiptune_2", "title": "Chiptune 2", "category": "chiptune", "file": "chiptune_2.wav", "creator": "drakzlin", "source": "https://opengameart.org/content/music-loops-0", "license": "CC0", "use": ["optional"]},
]

## Auto-BGM region -> trek (hanya yang cocok; ember/crypt = ambient, bukan di sini).
const AUTO_BGM: Dictionary = {
	"menu": "wandering_woodlands",
	"dawnroot_valley": "back_to_nature",
	"luminara_desert": "homestead",
}


static func get_track(track_id: String) -> Dictionary:
	for t: Dictionary in TRACKS:
		if str(t.get("id", "")) == track_id:
			return t
	return {}


static func file_for(track_id: String) -> String:
	var t: Dictionary = get_track(track_id)
	if t.is_empty():
		return ""
	return LIB_BASE + str(t.get("file", ""))


static func auto_bgm(region_id: String) -> String:
	return str(AUTO_BGM.get(region_id, ""))


static func tracks_for_use(use: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in TRACKS:
		if (t.get("use", []) as Array).has(use):
			out.append(t)
	return out
