extends Node

var configured: bool = false
var player_count: int = 2
var biome_id: String = ""

func configure(count: int, biome: String) -> void:
	player_count = count
	biome_id = biome
	configured = true
