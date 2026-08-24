extends Node2D
class_name Projectile

var velocity: Vector2 = Vector2.ZERO
var bounces_left: int = 0
var tunnel_ticks_left: int = 0
var gravity_scale: float = 1.0
var weapon_id: String = "bazooka"

func step(wind: float) -> void:
	velocity.y += Constants.GRAVITY * gravity_scale
	velocity.x += wind * 0.0035
	position += velocity
	queue_redraw()

func _draw() -> void:
	match weapon_id:
		"cluster":
			_draw_cluster()
		"bouncer":
			_draw_bouncer()
		"piercer":
			_draw_piercer()
		_:
			_draw_bazooka()

const OUTLINE := Color(0.086, 0.09, 0.106)

func _draw_bazooka() -> void:
	draw_circle(Vector2.ZERO, 7.5, Color("3f3f46"))
	draw_arc(Vector2.ZERO, 7.5, 0.0, TAU, 16, OUTLINE, 2.0)
	draw_circle(Vector2(3, -6), 2.6, Color("f59e0b"))
	draw_arc(Vector2(3, -6), 2.6, 0.0, TAU, 10, OUTLINE, 1.4)

func _draw_cluster() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("556b2f"))
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 16, OUTLINE, 2.0)
	draw_line(Vector2(-5, 0), Vector2(5, 0), Color(0, 0, 0, 0.35), 1.0)
	draw_line(Vector2(0, -5), Vector2(0, 5), Color(0, 0, 0, 0.35), 1.0)
	draw_rect(Rect2(-1.5, -9.5, 3, 3), Color("3f3f46"))
	draw_rect(Rect2(-1.5, -9.5, 3, 3), OUTLINE, false, 1.2)

func _draw_bouncer() -> void:
	draw_circle(Vector2.ZERO, 7.5, Color("65a30d"))
	draw_arc(Vector2.ZERO, 7.5, 0.0, TAU, 16, OUTLINE, 2.0)
	draw_circle(Vector2(-2, -2), 2.4, Color(1, 1, 1, 0.6))

func _draw_piercer() -> void:
	var angle := velocity.angle()
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	var body := PackedVector2Array([Vector2(10, 0), Vector2(-5, -4), Vector2(-2, 0), Vector2(-5, 4)])
	draw_colored_polygon(body, Color("fde047"))
	var closed := body.duplicate()
	closed.append(closed[0])
	draw_polyline(closed, OUTLINE, 1.6)
	draw_line(Vector2(-5, 0), Vector2(-12, 0), Color("fde047"), 3.0)
	draw_line(Vector2(-5, 0), Vector2(-12, 0), OUTLINE, 1.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
