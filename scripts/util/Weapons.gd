extends RefCounted
class_name Weapons

const LIST := [
	{
		"id": "bazooka",
		"name": "Mini Bazooka",
		"icon": "🚀",
		"explosion_radius": 36.0,
		"damage": 26.0,
		"bounces": 0,
		"cluster_count": 0,
		"cluster_radius": 0.0,
		"cluster_damage": 0.0,
	},
	{
		"id": "cluster",
		"name": "Racimo",
		"icon": "💥",
		"explosion_radius": 18.0,
		"damage": 8.0,
		"bounces": 0,
		"cluster_count": 4,
		"cluster_radius": 22.0,
		"cluster_damage": 16.0,
	},
	{
		"id": "bouncer",
		"name": "Rebote",
		"icon": "🎾",
		"explosion_radius": 30.0,
		"damage": 20.0,
		"bounces": 1,
		"cluster_count": 0,
		"cluster_radius": 0.0,
		"cluster_damage": 0.0,
	},
]

const DEFAULT_ID := "bazooka"

static func get_weapon(id: String) -> Dictionary:
	for w in LIST:
		if w.id == id:
			return w
	return LIST[0]
