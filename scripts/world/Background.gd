extends Node2D
class_name Background

const SKY_STOPS := [
	[0.0, Color("4fa8dc")],
	[0.45, Color("79c6ea")],
	[0.75, Color("bfe4f5")],
	[1.0, Color("e8f6fa")],
]

var clouds: Array = []

func _ready() -> void:
	_generate_clouds()

func _generate_clouds() -> void:
	clouds.clear()
	for i in 5:
		clouds.append({
			"x": randf() * Constants.SCREEN_W,
			"y": 30.0 + randf() * 110.0,
			"scale": 0.6 + randf() * 0.9,
			"speed": 0.08 + randf() * 0.12,
		})

func _physics_process(_delta: float) -> void:
	for c in clouds:
		c.x += c.speed
		if c.x > Constants.SCREEN_W + 40.0:
			c.x = -40.0
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_draw_sun()
	_draw_mountains()
	_draw_clouds()

func _draw_sky() -> void:
	var w := Constants.SCREEN_W
	var h := Constants.SCREEN_H
	var steps := 40
	for i in steps:
		var t0 := float(i) / steps
		var t1 := float(i + 1) / steps
		var col := DrawUtils.lerp_stops(SKY_STOPS, t0)
		draw_rect(Rect2(0, h * t0, w, h * (t1 - t0) + 1.0), col)

func _draw_sun() -> void:
	var sun := Vector2(Constants.SCREEN_W * 0.84, 70.0)
	var r := 70
	while r > 0:
		var t := float(r) / 70.0
		draw_circle(sun, r, Color(1.0, 0.957, 0.745, (1.0 - t) * 0.9))
		r -= 4
	draw_circle(sun, 24.0, Color("fff6d8"))

func _draw_mountains() -> void:
	var w := Constants.SCREEN_W
	var h := Constants.SCREEN_H
	var points := PackedVector2Array()
	points.append(Vector2(0, h * 0.5))
	var x := 0.0
	while x <= w:
		var y := h * 0.42 - sin(x * 0.006 + 1.3) * 22.0 - sin(x * 0.014) * 10.0
		points.append(Vector2(x, y))
		x += 20.0
	points.append(Vector2(w, h * 0.5))
	draw_colored_polygon(points, Color(120.0 / 255.0, 150.0 / 255.0, 170.0 / 255.0, 0.45))

func _draw_clouds() -> void:
	var col := Color(1, 1, 1, 0.85)
	for c in clouds:
		var center := Vector2(c.x, c.y)
		var s: float = c.scale
		draw_colored_polygon(DrawUtils.ellipse_points(center, 26.0 * s, 13.0 * s), col)
		draw_colored_polygon(DrawUtils.ellipse_points(center + Vector2(20, 4) * s, 18.0 * s, 11.0 * s), col)
		draw_colored_polygon(DrawUtils.ellipse_points(center + Vector2(-20, 4) * s, 18.0 * s, 11.0 * s), col)
