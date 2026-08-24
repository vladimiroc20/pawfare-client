extends Node2D

@onready var background: Background = $Background
@onready var root: Control = %Root
@onready var play_button: Button = %PlayButton
@onready var shop_button: Button = %ShopButton
@onready var settings_button: Button = %SettingsButton

func _ready() -> void:
	root.theme = UiTheme.build()
	background.set_biome(Biomes.random_biome())
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_play_pressed() -> void:
	Sfx.play("ui_click")
	get_tree().change_scene_to_file("res://scenes/menu/ModeSelect.tscn")

func _on_shop_pressed() -> void:
	Sfx.play("ui_click")
	get_tree().change_scene_to_file("res://scenes/menu/Shop.tscn")

func _on_settings_pressed() -> void:
	Sfx.play("ui_click")
	get_tree().change_scene_to_file("res://scenes/menu/Settings.tscn")
