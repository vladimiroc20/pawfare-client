extends Node2D

@onready var background: Background = $Background
@onready var root: Control = %Root
@onready var player_count_option: OptionButton = %PlayerCountOption
@onready var biome_option: OptionButton = %BiomeOption
@onready var mode_row: HBoxContainer = %ModeRow
@onready var mode_option: OptionButton = %ModeOption
@onready var play_button: Button = %PlayButton

func _ready() -> void:
	root.theme = UiTheme.build()
	background.set_biome(Biomes.random_biome())
	_populate_player_count()
	_populate_biomes()
	_populate_modes()
	_update_mode_visibility()
	play_button.pressed.connect(_on_play_pressed)

func _populate_player_count() -> void:
	player_count_option.clear()
	for n in range(Constants.MIN_PLAYERS, Constants.MAX_PLAYERS + 1):
		player_count_option.add_item("%d jugadores" % n, n)
	player_count_option.select(0)
	player_count_option.item_selected.connect(func(_i): _update_mode_visibility())

func _populate_biomes() -> void:
	biome_option.clear()
	biome_option.add_item("🎲 Aleatorio", 0)
	for i in Biomes.LIST.size():
		var b: Dictionary = Biomes.LIST[i]
		biome_option.add_item(str(b.icon, " ", b.name), i + 1)
	biome_option.select(0)

func _populate_modes() -> void:
	mode_option.clear()
	mode_option.add_item("Todos contra todos", 0)
	mode_option.add_item("Equipos (2 vs 2)", 1)
	mode_option.select(0)

func _update_mode_visibility() -> void:
	var count: int = player_count_option.get_item_id(player_count_option.selected)
	mode_row.visible = count == 4

func _on_play_pressed() -> void:
	var count: int = player_count_option.get_item_id(player_count_option.selected)
	var biome_index: int = biome_option.get_item_id(biome_option.selected)
	var biome_id: String = "" if biome_index == 0 else Biomes.LIST[biome_index - 1].id
	var team_mode: bool = mode_row.visible and mode_option.get_item_id(mode_option.selected) == 1

	GameConfig.configure(count, biome_id, team_mode)
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
