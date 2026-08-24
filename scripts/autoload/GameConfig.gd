extends Node

var configured: bool = false
var player_count: int = 2
var biome_id: String = ""
var team_mode: bool = false

func configure(count: int, biome: String, teams: bool = false) -> void:
	player_count = count
	biome_id = biome
	team_mode = teams
	configured = true
