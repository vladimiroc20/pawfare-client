extends Node2D

# Vitrina sin backend: muestra qué cosméticos existirán y los marca bloqueados.
# La tienda funcional (comprar/equipar de verdad) necesita cuentas de usuario
# primero — ver la sección de progresión del CLAUDE.md maestro.

@onready var background: Background = $Background
@onready var root: Control = %Root
@onready var grid: GridContainer = %Grid
@onready var back_button: Button = %BackButton

func _ready() -> void:
	root.theme = UiTheme.build()
	background.set_biome(Biomes.random_biome())
	back_button.pressed.connect(_on_back_pressed)
	_populate()

func _populate() -> void:
	for s in Species.LIST:
		_add_item(s.icon, s.name, "Skin de personaje")
	for w in Weapons.LIST:
		_add_item(w.icon, w.name, "Skin de arma")

func _add_item(icon: String, title: String, subtitle: String) -> void:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	panel.custom_minimum_size = Vector2(148, 150)
	panel.modulate = Color(1, 1, 1, 0.7)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(icon_label)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	title_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title_label)

	var sub_label := Label.new()
	sub_label.text = subtitle
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 11)
	sub_label.add_theme_color_override("font_color", Color(0.086, 0.09, 0.106, 0.6))
	vbox.add_child(sub_label)

	var lock_label := Label.new()
	lock_label.text = "🔒 Próximamente"
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lock_label)

	grid.add_child(panel)

func _on_back_pressed() -> void:
	Sfx.play("ui_click")
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
