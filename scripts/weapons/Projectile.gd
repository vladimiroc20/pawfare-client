extends Node2D
class_name Projectile

var velocity: Vector2 = Vector2.ZERO
var bounces_left: int = 0
var weapon_id: String = "bazooka"

func step(wind: float) -> void:
	velocity.y += Constants.GRAVITY
	velocity.x += wind * 0.0035
	position += velocity
	queue_redraw()

func _draw() -> void:
	match weapon_id:
		"cluster":
			_draw_cluster()
		"bouncer":
			_draw_bouncer()
		_:
			_draw_bazooka()

func _draw_bazooka() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("2d2d2d"))
	draw_line(Vector2(3, -6), Vector2(7, -11), Color("92400e"), 2.0)
	draw_circle(Vector2(7, -11), 2.5, Color("fbbf24"))

func _draw_cluster() -> void:
	draw_circle(Vector2.ZERO, 6.5, Color("556b2f"))
	draw_arc(Vector2.ZERO, 6.5, 0.0, TAU, 16, Color(0, 0, 0, 0.35), 1.2)
	draw_line(Vector2(-6, 0), Vector2(6, 0), Color(0, 0, 0, 0.35), 1.0)
	draw_line(Vector2(0, -6), Vector2(0, 6), Color(0, 0, 0, 0.35), 1.0)
	draw_rect(Rect2(-1.5, -9, 3, 3), Color("3f3f46"))

func _draw_bouncer() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("65a30d"))
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 16, Color(0.24, 0.35, 0.06, 0.8), 1.0)
	draw_circle(Vector2(-2, -2), 2.2, Color(1, 1, 1, 0.5))
