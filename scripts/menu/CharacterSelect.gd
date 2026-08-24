extends Node2D

const COUNTDOWN_SECONDS := 20.0

@onready var background: Background = $Background
@onready var root: Control = %Root
@onready var slots_row: HBoxContainer = %SlotsRow
@onready var countdown_label: Label = %CountdownLabel
@onready var skip_button: Button = %SkipButton

var mode: String = "local"
var slot_count: int = 1
var chosen_index: Array[int] = []
var touched: Array[bool] = []
var icon_labels: Array[Label] = []
var name_labels: Array[Label] = []

var time_left: float = COUNTDOWN_SECONDS
var finished: bool = false

func _ready() -> void:
	root.theme = UiTheme.build()
	background.set_biome(Biomes.random_biome())

	mode = GameConfig.character_select_mode
	slot_count = 1 if mode == "online" else GameConfig.player_count

	chosen_index.resize(slot_count)
	touched.resize(slot_count)
	for i in slot_count:
		chosen_index[i] = i % Species.LIST.size()
		touched[i] = false

	_build_slots()
	skip_button.pressed.connect(func(): Sfx.play("ui_click"); _finish())

func _build_slots() -> void:
	for i in slot_count:
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 6)

		var title := Label.new()
		title.text = "Tu personaje" if mode == "online" else Constants.PLAYER_LABELS[i % Constants.PLAYER_LABELS.size()]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 13)
		box.add_child(title)

		var icon_label := Label.new()
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 44)
		box.add_child(icon_label)
		icon_labels.append(icon_label)

		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name_label)
		name_labels.append(name_label)

		var arrows := HBoxContainer.new()
		arrows.alignment = BoxContainer.ALIGNMENT_CENTER
		arrows.add_theme_constant_override("separation", 8)

		var left := Button.new()
		left.text = "◀"
		left.pressed.connect(_cycle.bind(i, -1))
		arrows.add_child(left)

		var right := Button.new()
		right.text = "▶"
		right.pressed.connect(_cycle.bind(i, 1))
		arrows.add_child(right)

		box.add_child(arrows)
		slots_row.add_child(box)
		_refresh_slot(i)

func _cycle(i: int, delta: int) -> void:
	Sfx.play("ui_click")
	touched[i] = true
	chosen_index[i] = (chosen_index[i] + delta + Species.LIST.size()) % Species.LIST.size()
	_refresh_slot(i)
	if mode == "online":
		NetworkClient.select_character(Species.LIST[chosen_index[i]].id)

func _refresh_slot(i: int) -> void:
	var s: Dictionary = Species.LIST[chosen_index[i]]
	icon_labels[i].text = s.icon
	name_labels[i].text = s.name

func _process(delta: float) -> void:
	if finished:
		return
	time_left -= delta
	countdown_label.text = "La partida empieza en %d s..." % maxi(0, int(ceil(time_left)))
	if time_left <= 0.0:
		_finish()

func _finish() -> void:
	if finished:
		return
	finished = true

	for i in slot_count:
		if not touched[i]:
			chosen_index[i] = randi() % Species.LIST.size()
			if mode == "online":
				NetworkClient.select_character(Species.LIST[chosen_index[i]].id)

	if mode == "online":
		if get_tree():
			get_tree().change_scene_to_file("res://scenes/main/NetworkMain.tscn")
	else:
		GameConfig.chosen_species.clear()
		for i in slot_count:
			GameConfig.chosen_species.append(Species.LIST[chosen_index[i]].id)
		if get_tree():
			get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
