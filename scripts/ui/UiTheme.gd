extends RefCounted
class_name UiTheme

static func build() -> Theme:
	var theme := Theme.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.102, 0.102, 0.180, 0.88)
	panel_style.set_corner_radius_all(14)
	panel_style.set_content_margin_all(4)
	panel_style.border_color = Color(0.227, 0.227, 0.369, 0.9)
	panel_style.set_border_width_all(2)
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color("4f46e5")
	btn_normal.set_corner_radius_all(10)
	btn_normal.content_margin_left = 18.0
	btn_normal.content_margin_right = 18.0
	btn_normal.content_margin_top = 10.0
	btn_normal.content_margin_bottom = 10.0

	var btn_hover: StyleBoxFlat = btn_normal.duplicate()
	btn_hover.bg_color = Color("6366f1")

	var btn_pressed: StyleBoxFlat = btn_normal.duplicate()
	btn_pressed.bg_color = Color("4338ca")

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("focus", "Button", btn_hover)
	theme.set_color("font_color", "Button", Color.WHITE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)

	var opt_normal: StyleBoxFlat = btn_normal.duplicate()
	opt_normal.bg_color = Color(0.16, 0.16, 0.29, 1.0)
	var opt_hover: StyleBoxFlat = opt_normal.duplicate()
	opt_hover.bg_color = Color(0.22, 0.22, 0.37, 1.0)

	theme.set_stylebox("normal", "OptionButton", opt_normal)
	theme.set_stylebox("hover", "OptionButton", opt_hover)
	theme.set_stylebox("pressed", "OptionButton", opt_hover)
	theme.set_stylebox("focus", "OptionButton", opt_hover)
	theme.set_color("font_color", "OptionButton", Color.WHITE)
	theme.set_color("font_hover_color", "OptionButton", Color.WHITE)

	theme.set_color("font_color", "Label", Color.WHITE)

	var progress_bg := StyleBoxFlat.new()
	progress_bg.bg_color = Color(1, 1, 1, 0.15)
	progress_bg.set_corner_radius_all(6)
	theme.set_stylebox("background", "ProgressBar", progress_bg)

	return theme
