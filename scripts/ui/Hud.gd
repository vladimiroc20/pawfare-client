extends CanvasLayer
class_name Hud

const MEDALS := ["🥇", "🥈", "🥉", "4️⃣"]
const TEAM_NAMES := ["Equipo A", "Equipo B"]

signal restart_pressed
signal menu_pressed

@onready var root: Control = %Root
@onready var biome_label: Label = %BiomeLabel
@onready var health_row: HBoxContainer = %HealthRow
@onready var turn_label: Label = %TurnLabel
@onready var wind_label: Label = %WindLabel
@onready var hint_label: Label = %HintLabel
@onready var podium_panel: PanelContainer = %PodiumPanel
@onready var podium_list: VBoxContainer = %PodiumList
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton

var _bars: Dictionary = {}

func _ready() -> void:
	root.theme = UiTheme.build()
	restart_button.pressed.connect(func(): restart_pressed.emit())
	menu_button.pressed.connect(func(): menu_pressed.emit())
	restart_button.visible = false
	menu_button.visible = false
	podium_panel.visible = false

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
