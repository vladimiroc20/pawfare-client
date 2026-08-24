extends Node2D
class_name Projectile

var velocity: Vector2 = Vector2.ZERO

func step(wind: float) -> void:
	velocity.y += Constants.GRAVITY
	velocity.x += wind * 0.0035
	position += velocity
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("2d2d2d"))
	draw_line(Vector2(3, -6), Vector2(7, -11), Color("92400e"), 2.0)
	draw_circle(Vector2(7, -11), 2.5, Color("fbbf24"))
