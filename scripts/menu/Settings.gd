extends Node2D

@onready var background: Background = $Background
@onready var root: Control = %Root
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value_label: Label = %VolumeValueLabel
@onready var back_button: Button = %BackButton

func _ready() -> void:
	root.theme = UiTheme.build()
	background.set_biome(Biomes.random_biome())
	volume_slider.value = Sfx.master_volume
	_update_value_label()
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_slider.drag_ended.connect(_on_drag_ended)
	back_button.pressed.connect(_on_back_pressed)

func _on_volume_changed(value: float) -> void:
	Sfx.set_master_volume(value)
	_update_value_label()

func _on_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Sfx.play("ui_click")

func _update_value_label() -> void:
	volume_value_label.text = "%d%%" % int(round(Sfx.master_volume * 100))

func _on_back_pressed() -> void:
	Sfx.play("ui_click")
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
