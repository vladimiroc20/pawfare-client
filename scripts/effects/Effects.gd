extends Node2D
class_name Effects

var fx: Array = []
var debris: Array = []

func clear() -> void:
	fx.clear()
	debris.clear()

func spawn_explosion(x: float, y: float) -> void:
	fx.append({"type": "flash", "x": x, "y": y, "r": 4.0, "life": 1.0})
	fx.append({"type": "ring", "x": x, "y": y, "r": 6.0, "max_r": Constants.DAMAGE_RANGE, "life": 1.0})

func spawn_debris(x: float, y: float, count: int, size_ref: float) -> void:
	for i in count:
		debris.append({
			"x": x, "y": y,
			"vx": (randf() - 0.5) * 5.5,
			"vy": -randf() * 3.5 - 1.0,
			"size": 2.0 + randf() * minf(5.0, size_ref * 0.15),
			"rot": randf() * TAU,
			"vr": (randf() - 0.5) * 0.35,
			"life": 1.0,
			"color": Color(0.42, 0.447, 0.502),
		})

func spawn_ko_burst(x: float, y: float) -> void:
	fx.append({"type": "ko_ring", "x": x, "y": y, "r": 4.0, "max_r": 42.0, "life": 1.0})
	for i in 10:
		var a := TAU * i / 10.0
		debris.append({
			"x": x, "y": y,
			"vx": cos(a) * 2.6,
			"vy": sin(a) * 2.6 - 1.6,
			"size": 3.0 + randf() * 2.5,
			"rot": a,
			"vr": (randf() - 0.5) * 0.3,
			"life": 1.0,
			"color": Color("fde68a"),
		})

func _physics_process(_delta: float) -> void:
	_tick_fx()
	_tick_debris()
	queue_redraw()

func _tick_fx() -> void:
	for f in fx:
		if f.type == "ring" or f.type == "ko_ring":
			f.r += (f.max_r - f.r) * 0.35
			f.life -= 0.045
		else:
			f.r += 3.5
			f.life -= 0.09
	fx = fx.filter(func(f): return f.life > 0.0)

func _tick_debris() -> void:
	for d in debris:
		d.vy += 0.22
		d.x += d.vx
		d.y += d.vy
		d.rot += d.vr
		d.life -= 0.018
	debris = debris.filter(func(d): return d.life > 0.0 and d.y < Constants.SCREEN_H + 30.0)

func _draw() -> void:
	for f in fx:
		if f.type == "ring":
			draw_arc(Vector2(f.x, f.y), f.r, 0.0, TAU, 32, Color(1.0, 0.784, 0.353, f.life * 0.8), 3.0)
			draw_circle(Vector2(f.x, f.y), f.r, Color(1.0, 0.549, 0.078, f.life * 0.08))
		elif f.type == "ko_ring":
			draw_arc(Vector2(f.x, f.y), f.r, 0.0, TAU, 24, Color(1.0, 0.85, 0.3, f.life * 0.9), 3.0)
		else:
			draw_circle(Vector2(f.x, f.y), f.r, Color(1.0, 0.588, 0.118, f.life))
	for d in debris:
		var xform := Transform2D(d.rot, Vector2(d.x, d.y))
		draw_set_transform_matrix(xform)
		var s: float = d.size
		var base_color: Color = d.color
		draw_rect(Rect2(-s / 2.0, -s / 2.0, s, s), Color(base_color.r, base_color.g, base_color.b, maxf(0.0, d.life)))
	draw_set_transform_matrix(Transform2D.IDENTITY)
