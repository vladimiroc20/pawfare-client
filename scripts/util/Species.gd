extends RefCounted
class_name Species

const LIST := [
	{"id": "dog", "name": "Perro", "icon": "🐶"},
	{"id": "cat", "name": "Gato", "icon": "🐱"},
	{"id": "rabbit", "name": "Conejo", "icon": "🐰"},
	{"id": "panda", "name": "Panda", "icon": "🐼"},
	{"id": "fox", "name": "Zorro", "icon": "🦊"},
]

static func get_species(id: String) -> Dictionary:
	for s in LIST:
		if s.id == id:
			return s
	return LIST[0]

static func index_of(id: String) -> int:
	for i in LIST.size():
		if LIST[i].id == id:
			return i
	return 0

static func random_id() -> String:
	return LIST[randi() % LIST.size()].id
