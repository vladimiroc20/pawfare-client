extends Node2D
class_name Rock

var radius: float = 0.0
var health: float = 0.0
var max_health: float = 0.0
var has_accent: bool = false
var shape_points: Array = []

var rock_color: Color = Color("7d8896")
var accent_color: Color = Color(0.42, 0.557, 0.247, 0.55)

var terrain: Terrain
var fall_vy: float = 0.0

func _physics_process(_delta: float) -> void:
	if not terrain:
		return
	var ground_y := terrain.height_at(position.x)
	if position.y < ground_y - 1.0:
		# El terreno bajo la roca pudo desaparecer (un cráter cercano, o el túnel
		# del Perforador) sin que la roca recibiera el golpe — sin esto, se queda
		# flotando en el aire en vez de caer.
		fall_vy += Constants.KNOCK_GRAVITY
		position.y = minf(position.y + fall_vy, ground_y)
	else:
		fall_vy = 0.0

func apply_palette(base: Color, accent: Color) -> void:
	rock_color = base
	accent_color = accent
	queue_redraw()

func setup(r: float, hp: float) -> void:
	radius = r
	health = hp
	max_health = hp
	has_accent = radius > 22.0 and randf() < 0.7
	_generate_shape()
	queue_redraw()

func _generate_shape() -> void:
	shape_points.clear()
	var points := 7 + (randi() % 3)
	for i in points + 1:
		var a := PI * i / points
		var jitter := 0.8 + randf() * 0.35
		shape_points.append({"a": a, "rad": radius * jitter})

func take_hit() -> bool:
	health = maxf(0.0, health - Constants.ROCK_HIT_DAMAGE)
	queue_redraw()
	return health <= 0.0

func _draw() -> void:
	draw_colored_polygon(DrawUtils.ellipse_points(Vector2(0, 3), radius * 1.05, radius * 0.3), Color(0, 0, 0, 0.2))

	var pts := PackedVector2Array()
	for pt in shape_points:
		var a: float = pt.a
		var r: float = pt.rad
		pts.append(Vector2(cos(a) * r, -sin(a) * r))
	draw_colored_polygon(pts, rock_color)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color(0, 0, 0, 0.25), 2.0)

	if has_accent:
		draw_colored_polygon(DrawUtils.ellipse_points(Vector2(-radius * 0.3, -radius * 0.6), radius * 0.4, radius * 0.22, -0.3), accent_color)
		draw_colored_polygon(DrawUtils.ellipse_points(Vector2(radius * 0.35, -radius * 0.35), radius * 0.28, radius * 0.16, 0.4), accent_color)

	_draw_cracks()

func _draw_cracks() -> void:
	var damage_ratio := 1.0 - health / max_health
	if damage_ratio <= 0.0:
		return
	var crack_sets := 3
	if damage_ratio <= 0.66:
		crack_sets = 2
	if damage_ratio <= 0.33:
		crack_sets = 1
	var crack_lines := [
		[Vector2(-radius * 0.3, -radius * 0.2), Vector2(radius * 0.05, -radius * 0.75), Vector2(-radius * 0.15, -radius * 0.95)],
		[Vector2(radius * 0.1, -radius * 0.15), Vector2(radius * 0.4, -radius * 0.55)],
		[Vector2(-radius * 0.5, -radius * 0.1), Vector2(-radius * 0.2, -radius * 0.5), Vector2(radius * 0.1, -radius * 0.4)],
	]
	for i in crack_sets:
		var line: Array = crack_lines[i]
		draw_polyline(PackedVector2Array(line), Color(0.078, 0.078, 0.078, 0.55), 1.5)
