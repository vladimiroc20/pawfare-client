extends RefCounted
class_name Biomes

const LIST := [
	{
		"id": "backyard",
		"name": "Patio Trasero",
		"icon": "🌳",
		"is_night": false,
		"sky": [[0.0, Color("4fa8dc")], [0.45, Color("79c6ea")], [0.75, Color("bfe4f5")], [1.0, Color("e8f6fa")]],
		"terrain": [[0.0, Color("8bc34a")], [0.12, Color("6d9c3c")], [0.18, Color("8d6e4a")], [1.0, Color("5a4632")]],
		"grass": Color(0.235, 0.431, 0.157, 0.65),
		"mountain": Color(120.0 / 255.0, 150.0 / 255.0, 170.0 / 255.0, 0.45),
		"sun_color": Color("fff6d8"),
		"sun_glow": Color(1.0, 0.957, 0.745),
		"rock": Color("7d8896"),
		"rock_accent": Color(0.42, 0.557, 0.247, 0.55),
		"obstacle_delta": 0,
		"wind_scale": 1.0,
	},
	{
		"id": "beach",
		"name": "Playa",
		"icon": "🏖️",
		"is_night": false,
		"sky": [[0.0, Color("2fb8c9")], [0.45, Color("6fd3dd")], [0.75, Color("bdeef0")], [1.0, Color("f2fbe9")]],
		"terrain": [[0.0, Color("f4dfa3")], [0.15, Color("e8c97e")], [0.35, Color("d9b464")], [1.0, Color("8a6a3d")]],
		"grass": Color(0.72, 0.6, 0.32, 0.5),
		"mountain": Color(0.55, 0.75, 0.75, 0.35),
		"sun_color": Color("fff9e0"),
		"sun_glow": Color(1.0, 0.98, 0.8),
		"rock": Color("b8a888"),
		"rock_accent": Color(0.72, 0.6, 0.32, 0.5),
		"obstacle_delta": -1,
		"wind_scale": 1.4,
	},
	{
		"id": "night_forest",
		"name": "Bosque Nocturno",
		"icon": "🌲",
		"is_night": true,
		"sky": [[0.0, Color("0b1230")], [0.4, Color("1c2650")], [0.75, Color("32406e")], [1.0, Color("4a5a8a")]],
		"terrain": [[0.0, Color("2f4a2c")], [0.12, Color("233a20")], [0.18, Color("32261a")], [1.0, Color("1c140e")]],
		"grass": Color(0.15, 0.28, 0.13, 0.7),
		"mountain": Color(0.1, 0.12, 0.22, 0.55),
		"sun_color": Color("e6ecff"),
		"sun_glow": Color(0.85, 0.88, 1.0),
		"rock": Color("4a4f5c"),
		"rock_accent": Color(0.16, 0.32, 0.18, 0.6),
		"obstacle_delta": 1,
		"wind_scale": 0.8,
	},
	{
		"id": "snow",
		"name": "Cumbre Nevada",
		"icon": "❄️",
		"is_night": false,
		"sky": [[0.0, Color("7fa8c9")], [0.45, Color("aecbe0")], [0.75, Color("d8e8f2")], [1.0, Color("f4f9fc")]],
		"terrain": [[0.0, Color("f2f7fb")], [0.15, Color("d9e6f0")], [0.4, Color("aebfd0")], [1.0, Color("6c7c8f")]],
		"grass": Color(0.75, 0.82, 0.9, 0.5),
		"mountain": Color(0.7, 0.78, 0.88, 0.5),
		"sun_color": Color("f4faff"),
		"sun_glow": Color(0.9, 0.96, 1.0),
		"rock": Color("9aa7b5"),
		"rock_accent": Color(0.95, 0.97, 1.0, 0.65),
		"obstacle_delta": 0,
		"wind_scale": 1.2,
	},
	{
		"id": "urban_alley",
		"name": "Callejón Urbano",
		"icon": "🏙️",
		"is_night": false,
		"sky": [[0.0, Color("6b7789")], [0.45, Color("8b96a6")], [0.75, Color("b6bfc9")], [1.0, Color("d9dee3")]],
		"terrain": [[0.0, Color("9096a0")], [0.12, Color("7a808c")], [0.2, Color("6e6a63")], [1.0, Color("47433d")]],
		"grass": Color(0.4, 0.42, 0.44, 0.4),
		"mountain": Color(0.4, 0.43, 0.48, 0.5),
		"sun_color": Color("eef0f2"),
		"sun_glow": Color(0.85, 0.87, 0.9),
		"rock": Color("8a7f6f"),
		"rock_accent": Color(0.25, 0.24, 0.22, 0.55),
		"obstacle_delta": 1,
		"wind_scale": 0.6,
	},
]

static func get_biome(id: String) -> Dictionary:
	for b in LIST:
		if b.id == id:
			return b
	return LIST[0]

static func random_biome() -> Dictionary:
	return LIST[randi() % LIST.size()]
