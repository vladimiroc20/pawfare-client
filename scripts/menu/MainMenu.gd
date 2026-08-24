extends Node2D

@onready var background: Background = $Background
@onready var root: Control = %Root
@onready var player_count_option: OptionButton = %PlayerCountOption
@onready var biome_option: OptionButton = %BiomeOption
@onready var mode_row: HBoxContainer = %ModeRow
@onready var mode_option: OptionButton = %ModeOption
@onready var play_button: Button = %PlayButton
@onready var online_button: Button = %OnlineButton
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	root.theme = UiTheme.build()
	background.set_biome(Biomes.random_biome())
	_populate_player_count()
	_populate_biomes()
	_populate_modes()
	_update_mode_visibility()
	play_button.pressed.connect(_on_play_pressed)
	online_button.pressed.connect(_on_online_pressed)

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

func _selected_biome_id() -> String:
	var biome_index: int = biome_option.get_item_id(biome_option.selected)
	return "" if biome_index == 0 else Biomes.LIST[biome_index - 1].id

func _selected_team_mode() -> bool:
	return mode_row.visible and mode_option.get_item_id(mode_option.selected) == 1

func _on_play_pressed() -> void:
	var count: int = player_count_option.get_item_id(player_count_option.selected)
	GameConfig.configure(count, _selected_biome_id(), _selected_team_mode())
	GameConfig.character_select_mode = "local"
	get_tree().change_scene_to_file("res://scenes/menu/CharacterSelect.tscn")

func _on_online_pressed() -> void:
	var count: int = player_count_option.get_item_id(player_count_option.selected)
	play_button.disabled = true
	online_button.disabled = true
	status_label.text = "Buscando partida..."

	NetworkClient.joined.connect(_on_joined, CONNECT_ONE_SHOT)
	NetworkClient.join_failed.connect(_on_join_failed, CONNECT_ONE_SHOT)
	NetworkClient.quickmatch(count, _selected_team_mode(), _selected_biome_id())

func _on_joined(_state: Dictionary) -> void:
	GameConfig.character_select_mode = "online"
	get_tree().change_scene_to_file("res://scenes/menu/CharacterSelect.tscn")

func _on_join_failed(error: String) -> void:
	play_button.disabled = false
	online_button.disabled = false
	status_label.text = "No se pudo conectar: " + error
