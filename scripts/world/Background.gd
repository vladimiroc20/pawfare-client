extends Node2D
class_name Background

var sky_stops: Array = Biomes.LIST[0].sky
var mountain_color: Color = Biomes.LIST[0].mountain
var sun_color: Color = Biomes.LIST[0].sun_color
var sun_glow: Color = Biomes.LIST[0].sun_glow
var is_night: bool = false

var clouds: Array = []
var stars: Array = []

func _ready() -> void:
	_generate_clouds()
	_generate_stars()

func set_biome(biome: Dictionary) -> void:
	sky_stops = biome.sky
	mountain_color = biome.mountain
	sun_color = biome.sun_color
	sun_glow = biome.sun_glow
	is_night = biome.is_night
	queue_redraw()

func _generate_clouds() -> void:
	clouds.clear()
	for i in 5:
		clouds.append({
			"x": randf() * Constants.SCREEN_W,
			"y": 30.0 + randf() * 110.0,
			"scale": 0.6 + randf() * 0.9,
			"speed": 0.08 + randf() * 0.12,
		})

func _generate_stars() -> void:
	stars.clear()
	for i in 40:
		stars.append({
			"x": randf() * Constants.SCREEN_W,
			"y": randf() * Constants.SCREEN_H * 0.55,
			"r": 0.6 + randf() * 1.4,
			"a": 0.4 + randf() * 0.6,
		})

func _physics_process(_delta: float) -> void:
	for c in clouds:
		c.x += c.speed
		if c.x > Constants.SCREEN_W + 40.0:
			c.x = -40.0
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	if is_night:
		_draw_stars()
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
		var col := DrawUtils.lerp_stops(sky_stops, t0)
		draw_rect(Rect2(0, h * t0, w, h * (t1 - t0) + 1.0), col)

func _draw_stars() -> void:
	for s in stars:
		draw_circle(Vector2(s.x, s.y), s.r, Color(1, 1, 1, s.a))

func _draw_sun() -> void:
	var sun := Vector2(Constants.SCREEN_W * 0.84, 70.0)
	var max_r := 70 if not is_night else 46
	var r := max_r
	while r > 0:
		var t := float(r) / float(max_r)
		draw_circle(sun, r, Color(sun_glow.r, sun_glow.g, sun_glow.b, (1.0 - t) * (0.9 if not is_night else 0.5)))
		r -= 4
	draw_circle(sun, 24.0 if not is_night else 18.0, sun_color)

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
	draw_colored_polygon(points, mountain_color)

func _draw_clouds() -> void:
	var col := Color(1, 1, 1, 0.85 if not is_night else 0.25)
	for c in clouds:
		var center := Vector2(c.x, c.y)
		var s: float = c.scale
		draw_colored_polygon(DrawUtils.ellipse_points(center, 26.0 * s, 13.0 * s), col)
		draw_colored_polygon(DrawUtils.ellipse_points(center + Vector2(20, 4) * s, 18.0 * s, 11.0 * s), col)
		draw_colored_polygon(DrawUtils.ellipse_points(center + Vector2(-20, 4) * s, 18.0 * s, 11.0 * s), col)
