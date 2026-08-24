extends Node2D

@onready var background: Background = $Background
@onready var root: Control = %Root
@onready var local_card: Button = %LocalCard
@onready var quick_card: Button = %QuickCard
@onready var teams_card: Button = %TeamsCard
@onready var player_count_row: HBoxContainer = %PlayerCountRow
@onready var player_count_option: OptionButton = %PlayerCountOption
@onready var biome_option: OptionButton = %BiomeOption
@onready var cta_button: Button = %CtaButton
@onready var back_button: Button = %BackButton
@onready var status_label: Label = %StatusLabel

var selected_mode: String = "local"

func _ready() -> void:
	root.theme = UiTheme.build()
	background.set_biome(Biomes.random_biome())
	_populate_player_count()
	_populate_biomes()
	local_card.pressed.connect(func(): _select_mode("local"))
	quick_card.pressed.connect(func(): _select_mode("quick"))
	teams_card.pressed.connect(func(): _select_mode("teams"))
	cta_button.pressed.connect(_on_cta_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_select_mode("local")

func _select_mode(mode: String) -> void:
	Sfx.play("ui_click")
	selected_mode = mode
	player_count_row.visible = mode != "teams"
	cta_button.text = "▶ Jugar" if mode == "local" else "🔍 Buscar partida"
	status_label.text = ""

func _populate_player_count() -> void:
	player_count_option.clear()
	for n in range(Constants.MIN_PLAYERS, Constants.MAX_PLAYERS + 1):
		player_count_option.add_item("%d jugadores" % n, n)
	player_count_option.select(0)

func _populate_biomes() -> void:
	biome_option.clear()
	biome_option.add_item("🎲 Aleatorio", 0)
	for i in Biomes.LIST.size():
		var b: Dictionary = Biomes.LIST[i]
		biome_option.add_item(str(b.icon, " ", b.name), i + 1)
	biome_option.select(0)

func _selected_biome_id() -> String:
	var biome_index: int = biome_option.get_item_id(biome_option.selected)
	return "" if biome_index == 0 else Biomes.LIST[biome_index - 1].id

func _selected_player_count() -> int:
	if selected_mode == "teams":
		return 4
	return player_count_option.get_item_id(player_count_option.selected)

func _on_cta_pressed() -> void:
	Sfx.play("ui_click")
	if selected_mode == "local":
		GameConfig.configure(_selected_player_count(), _selected_biome_id(), false)
		GameConfig.character_select_mode = "local"
		get_tree().change_scene_to_file("res://scenes/menu/CharacterSelect.tscn")
		return

	var team_mode := selected_mode == "teams"
	cta_button.disabled = true
	status_label.text = "Buscando partida..."
	NetworkClient.joined.connect(_on_joined, CONNECT_ONE_SHOT)
	NetworkClient.join_failed.connect(_on_join_failed, CONNECT_ONE_SHOT)
	NetworkClient.quickmatch(_selected_player_count(), team_mode, _selected_biome_id())

func _on_joined(_state: Dictionary) -> void:
	GameConfig.character_select_mode = "online"
	get_tree().change_scene_to_file("res://scenes/menu/CharacterSelect.tscn")

func _on_join_failed(error: String) -> void:
	cta_button.disabled = false
	status_label.text = "No se pudo conectar: " + error

func _on_back_pressed() -> void:
	Sfx.play("ui_click")
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
