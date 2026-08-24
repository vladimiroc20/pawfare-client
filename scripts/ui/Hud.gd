extends CanvasLayer
class_name Hud

signal restart_pressed

@onready var biome_label: Label = %BiomeLabel
@onready var health_row: HBoxContainer = %HealthRow
@onready var turn_label: Label = %TurnLabel
@onready var wind_label: Label = %WindLabel
@onready var hint_label: Label = %HintLabel
@onready var winner_label: Label = %WinnerLabel
@onready var restart_button: Button = %RestartButton

var _bars: Dictionary = {}

func _ready() -> void:
	restart_button.pressed.connect(func(): restart_pressed.emit())
	restart_button.visible = false
	winner_label.text = ""

func setup_players(ids: Array, colors: Array, labels: Array) -> void:
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

func set_winner(text: String) -> void:
	winner_label.text = text

func show_restart(visible_: bool) -> void:
	restart_button.visible = visible_
