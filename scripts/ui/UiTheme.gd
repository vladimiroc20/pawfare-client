extends RefCounted
class_name UiTheme

# Mismo lenguaje visual que los personajes y las armas: contorno grueso y
# oscuro, colores planos y saturados, esquinas redondas — un "sticker", no un
# panel de control. Pensado para leerse bien a cualquier edad: texto grande,
# alto contraste, botones grandes con harto espacio para tocar.

const OUTLINE := Color(0.086, 0.09, 0.106)
const INK := Color(0.086, 0.09, 0.106)
const CREAM := Color(0.98, 0.96, 0.92)

const PRIMARY := Color("f59e0b") # naranja cálido — la acción principal (Jugar)
const PRIMARY_HOVER := Color("fbbf24")
const PRIMARY_PRESSED := Color("d97706")

const SECONDARY := Color("4f8ef7") # azul vivo — acciones secundarias
const SECONDARY_HOVER := Color("6ea3fb")
const SECONDARY_PRESSED := Color("3a72d1")

const NEUTRAL := Color("94a3b8") # gris azulado — volver/cancelar
const NEUTRAL_HOVER := Color("aebccb")
const NEUTRAL_PRESSED := Color("7a8ba0")

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 20

	_setup_panel(theme)
	_setup_button_variation(theme, "Button", PRIMARY, PRIMARY_HOVER, PRIMARY_PRESSED)
	_setup_button_variation(theme, "SecondaryButton", SECONDARY, SECONDARY_HOVER, SECONDARY_PRESSED)
	_setup_button_variation(theme, "NeutralButton", NEUTRAL, NEUTRAL_HOVER, NEUTRAL_PRESSED)
	_setup_option_button(theme)
	_setup_labels(theme)
	_setup_progress_bar(theme)
	_setup_slider(theme)

	return theme

static func _card_style(bg: Color, border_width: int = 4, radius: int = 22) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border_width)
	s.border_color = OUTLINE
	s.set_content_margin_all(4)
	return s

static func _setup_panel(theme: Theme) -> void:
	var panel := _card_style(CREAM)
	panel.shadow_size = 6
	panel.shadow_color = Color(0, 0, 0, 0.18)
	panel.shadow_offset = Vector2(0, 4)
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_type_variation("CardPanel", "PanelContainer")
	var card := _card_style(Color(1, 1, 1, 0.96), 4, 20)
	card.shadow_size = 5
	card.shadow_color = Color(0, 0, 0, 0.16)
	card.shadow_offset = Vector2(0, 3)
	theme.set_stylebox("panel", "CardPanel", card)

static func _setup_button_variation(theme: Theme, type_name: String, base: Color, hover: Color, pressed: Color) -> void:
	var normal := _card_style(base, 4, 18)
	normal.content_margin_left = 28.0
	normal.content_margin_right = 28.0
	normal.content_margin_top = 16.0
	normal.content_margin_bottom = 16.0
	normal.shadow_size = 4
	normal.shadow_color = Color(0, 0, 0, 0.22)
	normal.shadow_offset = Vector2(0, 4)

	var hover_style: StyleBoxFlat = normal.duplicate()
	hover_style.bg_color = hover

	var pressed_style: StyleBoxFlat = normal.duplicate()
	pressed_style.bg_color = pressed
	pressed_style.shadow_offset = Vector2(0, 1)

	var disabled_style: StyleBoxFlat = normal.duplicate()
	disabled_style.bg_color = base.lerp(Color(0.6, 0.6, 0.6), 0.55)
	disabled_style.shadow_size = 0

	if type_name != "Button":
		theme.set_type_variation(type_name, "Button")

	theme.set_stylebox("normal", type_name, normal)
	theme.set_stylebox("hover", type_name, hover_style)
	theme.set_stylebox("pressed", type_name, pressed_style)
	theme.set_stylebox("focus", type_name, hover_style)
	theme.set_stylebox("disabled", type_name, disabled_style)
	theme.set_color("font_color", type_name, Color.WHITE)
	theme.set_color("font_hover_color", type_name, Color.WHITE)
	theme.set_color("font_pressed_color", type_name, Color.WHITE)
	theme.set_color("font_focus_color", type_name, Color.WHITE)
	theme.set_color("font_disabled_color", type_name, Color(1, 1, 1, 0.75))
	theme.set_color("font_outline_color", type_name, OUTLINE)
	theme.set_constant("outline_size", type_name, 2)
	theme.set_font_size("font_size", type_name, 20)

static func _setup_option_button(theme: Theme) -> void:
	var normal := _card_style(Color(1, 1, 1, 0.9), 3, 14)
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 10.0
	var hover_style: StyleBoxFlat = normal.duplicate()
	hover_style.bg_color = Color(0.96, 0.96, 0.92)

	theme.set_stylebox("normal", "OptionButton", normal)
	theme.set_stylebox("hover", "OptionButton", hover_style)
	theme.set_stylebox("pressed", "OptionButton", hover_style)
	theme.set_stylebox("focus", "OptionButton", hover_style)
	theme.set_color("font_color", "OptionButton", INK)
	theme.set_color("font_hover_color", "OptionButton", INK)
	theme.set_font_size("font_size", "OptionButton", 18)

static func _setup_labels(theme: Theme) -> void:
	theme.set_color("font_color", "Label", INK)
	theme.set_font_size("font_size", "Label", 18)

	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font_size("font_size", "TitleLabel", 40)
	theme.set_color("font_color", "TitleLabel", Color.WHITE)
	theme.set_color("font_outline_color", "TitleLabel", OUTLINE)
	theme.set_constant("outline_size", "TitleLabel", 5)

	theme.set_type_variation("SkyLabel", "Label")
	theme.set_font_size("font_size", "SkyLabel", 18)
	theme.set_color("font_color", "SkyLabel", Color.WHITE)
	theme.set_color("font_outline_color", "SkyLabel", OUTLINE)
	theme.set_constant("outline_size", "SkyLabel", 3)

static func _setup_progress_bar(theme: Theme) -> void:
	var bg := _card_style(Color(0, 0, 0, 0.15), 2, 8)
	var fill := _card_style(PRIMARY, 2, 8)
	theme.set_stylebox("background", "ProgressBar", bg)
	theme.set_stylebox("fill", "ProgressBar", fill)

static func _setup_slider(theme: Theme) -> void:
	var groove := _card_style(Color(0, 0, 0, 0.15), 2, 8)
	var fill := _card_style(SECONDARY, 2, 8)
	theme.set_stylebox("slider", "HSlider", groove)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
