extends Node

var configured: bool = false
var player_count: int = 2
var biome_id: String = ""
var team_mode: bool = false

var character_select_mode: String = "local" # "local" o "online"
var chosen_species: Array[String] = []

func configure(count: int, biome: String, teams: bool = false) -> void:
	player_count = count
	biome_id = biome
	team_mode = teams
	configured = true
	chosen_species.clear()
