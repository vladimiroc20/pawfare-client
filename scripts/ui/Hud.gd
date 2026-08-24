extends CanvasLayer
class_name Hud

const MEDALS := ["🥇", "🥈", "🥉", "4️⃣"]
const TEAM_NAMES := ["Equipo A", "Equipo B"]

signal restart_pressed
signal menu_pressed
signal weapon_selected(weapon_id: String)

@onready var root: Control = %Root
@onready var biome_label: Label = %BiomeLabel
@onready var health_row: HBoxContainer = %HealthRow
@onready var turn_label: Label = %TurnLabel
@onready var wind_label: Label = %WindLabel
@onready var hint_label: Label = %HintLabel
@onready var weapon_row: HBoxContainer = %WeaponRow
@onready var podium_panel: PanelContainer = %PodiumPanel
@onready var podium_list: VBoxContainer = %PodiumList
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton

var _bars: Dictionary = {}
var _weapon_buttons: Dictionary = {}
var selected_weapon_id: String = Weapons.DEFAULT_ID

func _ready() -> void:
	root.theme = UiTheme.build()
	restart_button.pressed.connect(func(): restart_pressed.emit())
	menu_button.pressed.connect(func(): menu_pressed.emit())
	restart_button.visible = false
	menu_button.visible = false
	podium_panel.visible = false
	_setup_weapons()

func _setup_weapons() -> void:
	for w in Weapons.LIST:
		var btn := Button.new()
		btn.text = str(w.icon, " ", w.name)
		btn.toggle_mode = true
		btn.button_pressed = w.id == selected_weapon_id
		btn.pressed.connect(func(): _on_weapon_button_pressed(w.id))
		weapon_row.add_child(btn)
		_weapon_buttons[w.id] = btn

func _on_weapon_button_pressed(weapon_id: String) -> void:
	selected_weapon_id = weapon_id
	for id in _weapon_buttons:
		_weapon_buttons[id].button_pressed = id == weapon_id
	weapon_selected.emit(weapon_id)

func set_weapon_row_visible(visible_: bool) -> void:
	weapon_row.visible = visible_

func setup_players(ids: Array, colors: Array, labels: Array, teams: Array = []) -> void:
	for child in health_row.get_children():
		child.queue_free()
	_bars.clear()

	for i in ids.size():
		var id: String = ids[i]
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.text = String(labels[i])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		box.add_child(label)

		if i < teams.size() and int(teams[i]) != -1:
			var team_label := Label.new()
			team_label.text = TEAM_NAMES[int(teams[i])]
			team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			team_label.add_theme_font_size_override("font_size", 10)
			team_label.modulate = Color(1, 1, 1, 0.7)
			box.add_child(team_label)

		var bar := ProgressBar.new()
		bar.max_value = 100.0
		bar.value = 100.0
		bar.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = colors[i]
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill)
		box.add_child(bar)

		health_row.add_child(box)
		_bars[id] = bar

func set_biome_text(text: String) -> void:
	biome_label.text = text

func set_health(player_id: String, value: float) -> void:
	if _bars.has(player_id):
		_bars[player_id].value = value

func set_turn_text(text: String) -> void:
	turn_label.text = text

func set_wind_text(text: String) -> void:
	wind_label.text = text

func set_hint(text: String) -> void:
	hint_label.text = text

func hide_podium() -> void:
	podium_panel.visible = false

func show_podium(ranking: Array, labels: Dictionary) -> void:
	for child in podium_list.get_children():
		child.queue_free()

	podium_panel.visible = not ranking.is_empty()
	for entry in ranking:
		var place: int = entry.place
		var medal: String = MEDALS[clampi(place - 1, 0, MEDALS.size() - 1)]
		var names: Array = entry.ids.map(func(id): return String(labels.get(id, id)))

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)

		var medal_label := Label.new()
		medal_label.text = medal
		medal_label.add_theme_font_size_override("font_size", 20)
		row.add_child(medal_label)

		var name_label := Label.new()
		name_label.text = ", ".join(names)
		name_label.add_theme_font_size_override("font_size", 15)
		row.add_child(name_label)

		podium_list.add_child(row)

func show_restart(visible_: bool) -> void:
	restart_button.visible = visible_
	menu_button.visible = visible_
	if visible_:
		set_weapon_row_visible(false)
