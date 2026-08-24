extends Node2D

@onready var background: Background = $Background
@onready var player_count_option: OptionButton = %PlayerCountOption
@onready var biome_option: OptionButton = %BiomeOption
@onready var play_button: Button = %PlayButton

func _ready() -> void:
	background.set_biome(Biomes.random_biome())
	_populate_player_count()
	_populate_biomes()
	play_button.pressed.connect(_on_play_pressed)

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

func _on_play_pressed() -> void:
	var count: int = player_count_option.get_item_id(player_count_option.selected)
	var biome_index: int = biome_option.get_item_id(biome_option.selected)
	var biome_id: String = "" if biome_index == 0 else Biomes.LIST[biome_index - 1].id

	GameConfig.configure(count, biome_id)
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
