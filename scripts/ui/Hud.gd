extends CanvasLayer
class_name Hud

signal restart_pressed

@onready var hp1_bar: ProgressBar = %Hp1Bar
@onready var hp2_bar: ProgressBar = %Hp2Bar
@onready var turn_label: Label = %TurnLabel
@onready var wind_label: Label = %WindLabel
@onready var hint_label: Label = %HintLabel
@onready var winner_label: Label = %WinnerLabel
@onready var restart_button: Button = %RestartButton

func _ready() -> void:
	restart_button.pressed.connect(func(): restart_pressed.emit())
	restart_button.visible = false
	winner_label.text = ""

func set_health(player_id: String, value: float) -> void:
	if player_id == "p1":
		hp1_bar.value = value
	else:
		hp2_bar.value = value

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
